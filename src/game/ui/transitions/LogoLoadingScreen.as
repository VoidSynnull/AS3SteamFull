package game.ui.transitions
{
	import com.greensock.TweenLite;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.filters.BitmapFilterQuality;
	import flash.filters.DropShadowFilter;
	import flash.text.AntiAliasType;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;
	import engine.group.DisplayGroup;
	
	import game.data.TimedEvent;
	import game.data.ui.ToolTipType;
	import game.ui.transitions.components.LoadingScreenLetterComponent;
	import game.ui.transitions.systems.LoadingScreenLetterSystem;
	import game.util.ArrayUtils;
	import game.util.DataUtils;
	import game.util.EntityUtils;
	import game.util.PlatformUtils;
	import game.util.SceneUtil;
	import game.util.TextUtils;
	import game.util.TweenUtils;
	
	public class LogoLoadingScreen extends DisplayGroup implements ITransition
	{
		public function LogoLoadingScreen(container:DisplayObjectContainer=null)
		{
			super(container);
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{
			// set the prefix for the assets path.
			super.groupPrefix = "ui/transitions/";
			
			// Create this groups container.
			super.init(container);
			
			// load this groups assets.
			load();
		}
		
		override public function load():void
		{	
			super.loadFiles(new Array("logoLoadingScreen.swf", "hints.xml"), false, true, loaded );
		}
				
		// all assets ready
		override public function loaded():void
		{
			// if this group has been removed before it has finished loading halt setup.
			if(super.groupContainer == null)
			{
				return;
			}
			
			_screen = super.getAsset("logoLoadingScreen.swf", true) as MovieClip;
			
			super.groupContainer.addChild(_screen);
			
			if(!PlatformUtils.isMobileOS)
			{
				_screen.alpha = 0;
				this.addSystem(new LoadingScreenLetterSystem());
				_screen.removeChild(_screen.simpleProgress);
			}
			else
			{
				_screen.x += super.shellApi.viewportDeltaX * .5;
				_screen.y += super.shellApi.viewportDeltaY * .5;
			}
			
			_screen.mouseChildren = false;
			_screen.mouseEnabled = false;
			
			super.shellApi.defaultCursor = ToolTipType.ARROW;
			
			setupHints();
			
			super.loaded();
		}
		
		public function transitionIn(callback:Function = null):void
		{
			if(!PlatformUtils.isMobileOS)
			{
				setupPoptropicaLogo();
			}
		}
		
		public function transitionOut(callback:Function = null):void
		{
			_callback = callback;
			
			if(_displayed)
			{
				for(var i:int=1; i<=16; i++)
				{
					var entity:Entity = getEntityById("letter" + i);
					var l:LoadingScreenLetterComponent = entity.get(LoadingScreenLetterComponent);
					l.startY = -100;
					l.baseY = -100;
				}
	
				SceneUtil.addTimedEvent(this, new TimedEvent(.75, 1, allDone));
			}
			else
			{
				super.stopFileLoad(new Array("logoLoadingScreen.swf", "hints.xml"));
				allDone();
			}
			
			if(_hintText != null && _hintText.parent != null)
			{
				_hintText.parent.removeChild(_hintText);
			}
		}
		
		public function transitionReady():void
		{
			// not used
		}
				
		private function setupHints():void
		{
			var hintData:XML = super.getData("hints.xml");
			
			if(hintData)
			{
				_hints = new Array();
				
				for each(var hint:XML in hintData.hint)
				{
					if(DataUtils.isNull(hint.attribute("platform")) || hint.attribute("platform") == PlatformUtils.platformDescription)
					{
						_hints.push(hint.toString());
					}
				}
				
				if(_hints.length > 0)
				{
					ArrayUtils.shuffleArray(_hints);
					
					_hintText = new TextField();
					
					var style:String = "loadinghintsmobile";
			
					if(PlatformUtils.isDesktop)
					{
						style = "loadinghints";
					}
					
					TextUtils.applyStyle(super.shellApi.textManager.getStyleData("ui", style), _hintText);
					_hintText.embedFonts = true
					_hintText.antiAliasType = AntiAliasType.NORMAL;
					_hintText.autoSize = TextFieldAutoSize.CENTER;
					_hintText.multiline = true;
					_hintText.height = super.shellApi.viewportHeight * .5;
					
					var glow:DropShadowFilter = new DropShadowFilter(0, 0, 0x0083F2, 1, 2, 2, 12, BitmapFilterQuality.HIGH);
					_hintText.filters = [glow];
					
					var textContainer:Sprite = new Sprite();
					textContainer.addChild(_hintText);
					
					super.groupContainer.addChild(textContainer);
					
					// add basic components to groupEntity to allow tweens.
					super.groupEntity.add(new Display(textContainer));
					super.groupEntity.add(new Spatial(0, 0));
					
					SceneUtil.addTimedEvent(this, new TimedEvent(2.5, 1, loadNextHint));
				}
			}
		}
		
		private function loadNextHint():void
		{
			if(!super.removalPending)
			{
				var hint:String = _hints[_hintIndex];
				_hintText.text = hint;
				
				var bottomOffset:int = 145;
				var textHeight:int = 40;
				
				if(PlatformUtils.isDesktop)
				{
					bottomOffset = 90;
					textHeight = 24;
				}
				
				// position the hints based on # of lines and width.
				var widthRatio:int = Math.ceil(_hintText.width / super.shellApi.viewportWidth);
				
				if(widthRatio > 1)
				{
					_hintText.text = TextUtils.formatAsBlock(hint, hint.length / widthRatio);
				}
				
				_hintText.x = super.shellApi.viewportWidth * .5 - _hintText.width * .5;
				_hintText.y = super.shellApi.viewportHeight - bottomOffset - textHeight * (widthRatio - 1);
				
				_hintIndex++;
				
				if(_hintIndex >= _hints.length)
				{
					_hintIndex = 0;
				}
				
				Display(super.getGroupEntityComponent(Display)).alpha = 0;
				
				var hintMinTime:int = 2;
				var hintTimeMultiplier:Number = 0.05;
				var waitTime:Number = hintMinTime + (super.shellApi.profileManager.active.dialogSpeed * hintTimeMultiplier) * _hintText.text.length;
				TweenUtils.entityTo(super.groupEntity, Display, .5, { alpha : 1 });
				SceneUtil.addTimedEvent(this, new TimedEvent(waitTime, 1, fadeHint));
			}
		}
		
		private function fadeHint():void
		{
			if(!super.removalPending)
			{
				TweenUtils.entityTo(super.groupEntity, Display, .5, { alpha : 0, onComplete : loadNextHint });
			}
		}
		
		private function allDone():void
		{
			if(_callback)
			{
				_callback();
			}
			
			super.remove();
		}
		
		private function setupPoptropicaLogo():void
		{
			for(var i:int=1; i<=16; i++)
			{
				var do3D:Boolean = false;
				if (i < 11) {
					do3D = true;
				}
				var doWave:Boolean = true;
				if (i > 11) {
					doWave = false;
				}
				
				var entity:Entity = EntityUtils.createSpatialEntity(this, _screen["l" + i]);
				entity.add(new Id("letter" + i));
				Spatial(entity.get(Spatial)).x += super.shellApi.viewportDeltaX * .5;
				Spatial(entity.get(Spatial)).y += super.shellApi.viewportDeltaY * .5;
				entity.add(new LoadingScreenLetterComponent(entity.get(Spatial), i, doWave, do3D, do3D));
				//entity.add(shellApi.inputEntity.get(Input));
			
				Spatial(entity.get(Spatial)).y = -50 - i*(50 + super.shellApi.viewportDeltaY * .5);
			}
			
			// don't show the screen until after the next system update.  This will give the logo letter system a chance to do its update and place the letters where they belong.
			super.systemManager.updateComplete.addOnce(showScreen);
			
			_displayed = true;
		}
		
		private function showScreen():void
		{
			_screen.alpha = 1;
		}
		
		public function get manualClose():Boolean
		{
			return(false);
		}
		
		public var fadeInTime:Number = .5;
		public var fadeOutTime:Number = 3.5;
		private var _displayed:Boolean = false;
		private var _tween:TweenLite;
		private var _callback:Function;
		private var _screen:MovieClip;
		private var _hintText:TextField;
		private var _hintIndex:int = 0;
		private var _hints:Array;
	}
}