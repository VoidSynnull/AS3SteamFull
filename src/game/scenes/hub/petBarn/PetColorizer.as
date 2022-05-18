package game.scenes.hub.petBarn
{
	import com.greensock.easing.Bounce;
	import com.greensock.easing.Sine;
	
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.ColorTransform;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.MotionBounds;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.creators.InteractionCreator;
	
	import game.components.Emitter;
	import game.components.motion.Draggable;
	import game.components.ui.Ratio;
	import game.components.ui.Slider;
	import game.creators.entity.EmitterCreator;
	import game.creators.ui.ButtonCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.animation.entity.character.Pop;
	import game.data.character.LookAspectData;
	import game.data.character.LookData;
	import game.data.specialAbility.SpecialAbilityData;
	import game.data.ui.TransitionData;
	import game.scene.template.CharacterGroup;
	import game.scenes.hub.petBarn.ColorizerSteam;
	import game.systems.motion.DraggableSystem;
	import game.systems.ui.SliderSystem;
	import game.ui.popup.Popup;
	import game.util.BitmapUtils;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.Utils;
	
	public class PetColorizer extends Popup
	{
		private var content:MovieClip;
		
		private var _colorsBitmapData:BitmapData;
		private var _color:uint;
		private var _changedColors:Boolean = false;
		private var _showerTween:Tween;
		private var _animating:Boolean = false;
		private var _data:SpecialAbilityData;
		
		private var _dummy:Entity;
		private var _steam:Entity;
		private var _selector:Entity;
		private var _selectorBack:Entity;
		private var _slider:Entity;
		private var _sliderBack:Entity;
		
		private var _shower:DisplayObject;
		private var _overlayWhite:DisplayObject;
		private var _overlayBlack:DisplayObject;
		private var _buttonColor:DisplayObject;
		
		public function PetColorizer(container:DisplayObjectContainer = null)
		{
			super(container);
			
			this.id 				= "PetColorizer";
			this.groupPrefix 		= "scenes/hub/petbarn/colorizer/";
			this.screenAsset 		= "colorizer.swf";
			this.pauseParent 		= true;
			this.darkenBackground 	= true;
		}
		
		override public function destroy():void
		{
			_colorsBitmapData.dispose();
			_colorsBitmapData = null;
			super.destroy();
		}
		
		override public function init(container:DisplayObjectContainer = null):void
		{
			this.transitionIn 			= new TransitionData();
			this.transitionIn.duration 	= 0.9;
			this.transitionIn.startPos 	= new Point(0, -super.shellApi.viewportHeight);
			this.transitionIn.endPos 	= new Point(0, 0);
			this.transitionIn.ease 		= Bounce.easeOut;
			this.transitionOut 			= transitionIn.duplicateSwitch(Sine.easeIn);
			this.transitionOut.duration = 0.3;
			
			super.init(container);
			this.load();
		}
		
		override public function loaded():void
		{
			super.loaded();
			
			// hide popup until pet loaded
			this.screen.visible = false;
			
			// add systems
			this.addSystem(new DraggableSystem());
			this.addSystem(new SliderSystem());
			
			// setup tween for shower
			this._showerTween = this.getGroupEntityComponent(Tween);
			
			// reference to button color clip
			_buttonColor = this.screen.content.colorizeBtn.buttonColor;
			
			// create buttons------------
			content = this.screen.content;
			ButtonCreator.createButtonEntity(content.acceptBtn, this, this.onAccept, null, null, null, true, true);
			ButtonCreator.createButtonEntity(content.cancelBtn, this, this.onCancel, null, null, null, true, true);
			ButtonCreator.createButtonEntity(content.colorizeBtn, this, this.changeSkinColor);
			
			// setup shower---------------
			var shower:DisplayObject = content.shower;
			shower.scaleX = 0;
			var bounds:Rectangle = shower.getBounds(shower);
			bounds.inflate(40, 20);
			_shower = this.createBitmapSprite(shower, 1, bounds);
			
			// setup steam-----------------
			_steam = EmitterCreator.create(this, content.steam, new ColorizerSteam(), 0, 0, null, null, null, false);
			Emitter(_steam.get(Emitter)).emitter.start();
			Emitter(_steam.get(Emitter)).emitter.counter.stop();
			
			// setup pet---------------
			_data = shellApi.specialAbilityManager.getAbility("pets/pop_follower");
			if (_data == null)
			{
				trace("PetColorizer: no active pet found to display!");
			}
			else
			{
				var lookData:LookData = _data.specialAbility.getLook();
				var characterGroup:CharacterGroup = super.getGroupById("characterGroup" ) as CharacterGroup;
				_dummy = characterGroup.createDummy("dummy", lookData, "left", "pet_babyquad", content, this, petLoaded, false, 1);
			}
			
			// setup selector---------
			_selector = EntityUtils.createSpatialEntity(this, content.selector);
			InteractionCreator.addToEntity(_selector, [InteractionCreator.DOWN, InteractionCreator.UP, InteractionCreator.RELEASE_OUT]);
			ToolTipCreator.addToEntity(_selector);
			_selector.add(new MotionBounds(new Rectangle(124.3, 24.4, 105.5, 87.3)));
			var draggable:Draggable = new Draggable();
			draggable.dragging.add(this.onSelectorDragging);
			_selector.add(draggable);
			_selectorBack = ButtonCreator.createButtonEntity(content.selectorBack, this, this.onSelectorDragging, null, null, null, true, true);
			
			// setup slider-------------
			_overlayWhite = content.colors.overlayWhite;
			_overlayBlack = content.colors.overlayBlack;
			_slider = EntityUtils.createSpatialEntity(this, content.slider);
			InteractionCreator.addToEntity(_slider, [InteractionCreator.DOWN, InteractionCreator.UP, InteractionCreator.RELEASE_OUT]);
			ToolTipCreator.addToEntity(_slider);
			_slider.add(new MotionBounds(new Rectangle(108, 149, 141, 0)));
			_slider.add(new Ratio(0.5));
			_slider.add(new Slider());
			draggable = new Draggable("x");
			draggable.dragging.add(this.onSliderDragging);
			_slider.add(draggable);
			_sliderBack = ButtonCreator.createButtonEntity(content.sliderBack, this, this.onSliderDragging, null, null, null, true, true);
			
			// create bitmap data--------------
			createColorBitmapData();
		}
		
		// when pet is loaded
		private function petLoaded(entity:Entity):void
		{
			// position pet
			var spatial:Spatial = _dummy.get(Spatial);
			spatial.x = -65;
			spatial.y = 132;
			
			// scale pet
			CharUtils.setScale(entity, 2.5);
			
			// put the pet behind the shower
			var display:DisplayObject = _dummy.get(Display).displayObject;
			display.parent.setChildIndex(display, display.parent.numChildren - 2);
			
			// allow time for pet to load
			var timedEvent:TimedEvent = new TimedEvent(4, 1, colorizerReady);
			timedEvent.countByUpdate = true;
			SceneUtil.addTimedEvent(this, timedEvent);
		}
		
		// when delay is complete
		private function colorizerReady():void
		{
			this.screen.visible = true;
		}
		
		// get color from rainbow spectrum
		private function getBitmapDataColor():void
		{
			// get selector position
			var spatial:Spatial = _selector.get(Spatial);
			
			// limit to bounds
			var bounds:Rectangle = MotionBounds(_selector.get(MotionBounds)).box;
			var x:Number = spatial.x;
			var y:Number = spatial.y;
			if (x < bounds.left)
				x = bounds.left;
			else if (x > bounds.right)
				x = bounds.right;
			if (y < bounds.top)
				y = bounds.top;
			else if (y > bounds.bottom)
				y = bounds.bottom;
			
			// get color based on coords
			_color = _colorsBitmapData.getPixel(x - content.colors.x, y - content.colors.y);
			
			// update button color
			var colorTransform:ColorTransform 		= _buttonColor.transform.colorTransform;
			colorTransform.color 					= _color;
			_buttonColor.transform.colorTransform 	= colorTransform;
		}
		
		// while selector is dragging
		private function onSelectorDragging(entity:Entity):void
		{
			if (entity == _selectorBack)
			{
				var box:Rectangle = _selector.get(MotionBounds).box;
				var posX:Number = box.left + entity.get(Display).displayObject.mouseX;
				// need to force 10 pixels inside box
				if (posX < 10)
					posX = 0;
				else if (posX > box.right + 20)
					posX = box.right;
				else
					posX -= 10;
				var posY:Number = box.top + entity.get(Display).displayObject.mouseY;
				if (posY < 10)
					posY = 0;
				else if (posY > box.bottom + 20)
					posY = box.bottom;
				else
					posY -= 10;
				_selector.get(Spatial).x = posX;
				_selector.get(Spatial).y = posY;
			}
			this.getBitmapDataColor();
		}
		
		// while slider is dragging
		private function onSliderDragging(entity:Entity):void
		{
			if (entity == _sliderBack)
			{
				var box:Rectangle = _slider.get(MotionBounds).box;
				var pos:Number = box.left + entity.get(Display).displayObject.mouseX;
				_slider.get(Ratio).decimal = Utils.toDecimal(pos, box.left, box.right);
			}
			var decimal:Number 		= _slider.get(Ratio).decimal;
			_overlayWhite.alpha 	= Utils.toDecimal(decimal, 0.5, 1);
			_overlayBlack.alpha 	= Utils.toDecimal(decimal, 0.5, 0);
			createColorBitmapData();
		}
		
		// create bitmap data object
		private function createColorBitmapData():void
		{
			_colorsBitmapData = BitmapUtils.createBitmapData(this.screen.content.colors);
			getBitmapDataColor();
		}
		
		// when clicking on colorize button
		private function changeSkinColor(entity:Entity):void
		{
			// set flag
			_changedColors = true;
			
			// if not animating then animate steam and shower
			if (!_animating)
			{
				_animating = true;
				
				// show steam
				Emitter(_steam.get(Emitter)).emitter.counter.resume();
				
				// show shower
				var colorTransform:ColorTransform 	= _shower.transform.colorTransform;
				colorTransform.color 				= _color;
				_shower.transform.colorTransform 	= colorTransform;
				
				// tween shower
				this._showerTween.to(this._shower, 0.5, {scaleX:1, onComplete:this.onShowerScaleOut});
			}
		}
		
		private function onShowerScaleOut():void
		{
			this._showerTween.to(this._shower, 0.25, {scaleX:0, onComplete:this.onShowerScaleIn});
			
			CharUtils.setAnim(_dummy, Pop);
			SkinUtils.setSkinPart(_dummy, SkinUtils.SKIN_COLOR, _color);
		}
		
		private function onShowerScaleIn():void
		{
			_animating = false;
			Emitter(_steam.get(Emitter)).emitter.counter.stop();
		}
		
		// click accept button
		private function onAccept(entity:Entity):void
		{
			// if changed colors
			if (_changedColors)
			{
				// get look and apply color
				var lookData:LookData = _data.specialAbility.getLook();
				var lookAspect:LookAspectData = new LookAspectData( SkinUtils.SKIN_COLOR, _color); 
				lookData.applyAspect(lookAspect);
				_data.specialAbility.setLook(lookData);
			}
			this.playClick();
			this.close();
		}
		
		// when click cancel
		private function onCancel(entity:Entity):void
		{
			this.playCancel();
			this.close();
		}
	}
}