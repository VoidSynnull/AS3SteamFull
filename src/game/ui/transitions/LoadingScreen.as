package game.ui.transitions
{
	import com.greensock.TweenLite;
	import com.greensock.easing.Linear;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import engine.group.UIView;
	import engine.util.Command;
	
	public class LoadingScreen extends UIView implements ITransition
	{
		public function LoadingScreen(container:DisplayObjectContainer=null)
		{
			super(container);
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{
			// set the prefix for the assets path.
			super.groupPrefix = "ui/transitions/";
			super.screenAsset = "loading.swf";
			
			// Create this groups container.
			super.init(container);
			
			// load this groups assets.
			load();
		}
		
		override public function load():void
		{	
			super.loadFiles(new Array( this.screenAsset), false, true, loaded );
			super.shellApi.screenManager.setSize();
		}
		
		// all assets ready
		override public function loaded():void
		{			
			if(!_closeRequest)
			{
				super.screen = super.getAsset( super.screenAsset, true) as MovieClip;
				super.groupContainer.addChild(super.screen);
				
				// reposition for device
				super.layout.fitUI(super.screen);
				
				super.groupContainer.mouseChildren = false;
				super.groupContainer.mouseEnabled = false;
			}
			
			super.shellApi.screenManager.setSize();
			this.groupReady();
		}
		
		public function transitionIn(callback:Function = null):void
		{
			if(super.screen)
			{
				super.screen.visible = true;
				super.screen.alpha = 0;
				// TODO : switch to entity based tween
				_tween = TweenLite.to(super.screen, fadeInTime, { delay : .7, alpha : 1, ease:Linear.easeNone, onComplete : callback } );
			}
		}
		
		public function transitionOut(callback:Function = null):void
		{
			if(super.screen)
			{
				super.screen.visible = true;
				super.screen.alpha = 1;
				_tween.kill();
				// TODO : switch to entity based tween
				_tween = TweenLite.to(super.screen, fadeOutTime, { alpha : 0, ease:Linear.easeNone, onComplete : Command.create(transitionDone, callback) } );
			}
			else
			{
				_closeRequest = true;
			}
		}
		
		public function transitionDone(callback:Function = null):void
		{
			if(super.screen)
			{
				super.screen.visible = false;
			}
		}
		
		public function transitionReady():void
		{
			// not used
		}
		
		public function get manualClose():Boolean
		{
			return(false);
		}
		
		public var fadeInTime:Number = .5;
		public var fadeOutTime:Number = .5;
		private var _tween:TweenLite;
		private var _closeRequest:Boolean = false;
	}
}