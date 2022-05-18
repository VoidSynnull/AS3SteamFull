package game.scenes.examples.gestureExample
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.events.TransformGestureEvent;
	import flash.ui.Multitouch;
	import flash.ui.MultitouchInputMode;
	
	import engine.group.Scene;
	
	import game.util.SceneUtil;
	
	public class GestureExample extends Scene
	{
		public function GestureExample()
		{
			Multitouch.inputMode = MultitouchInputMode.GESTURE;
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{		
			super.init(container);
			super.groupPrefix = "scenes/examples/gestureExample/";
			load();
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			shellApi.fileLoadComplete.addOnce(loaded);
			loadFiles(["background.swf", "hits.swf"]);
		}
		
		// all assets ready
		override public function loaded():void
		{
			var background:MovieClip = this.groupContainer.addChild(getAsset("background.swf", true)) as MovieClip;
			background.width = this.shellApi.viewportWidth;
			background.height = this.shellApi.viewportHeight;
			
			var hits:MovieClip = this.groupContainer.addChild(getAsset("hits.swf", true)) as MovieClip;
			_pacDizzle = hits["pacdizzle"];
			
			_pacDizzle.x = 20;
			_pacDizzle.y = shellApi.viewportHeight - 20;
			
			this.container.addEventListener(TransformGestureEvent.GESTURE_SWIPE, swipeHandler);
			background.addEventListener(TransformGestureEvent.GESTURE_SWIPE, swipeHandler);
			
			SceneUtil.hideCustomCursor(shellApi.inputEntity);
			
			super.loaded();
		}
		
		private function swipeHandler(evt:TransformGestureEvent):void
		{
			trace(evt.phase);
			_pacDizzle.alpha = Math.random() -.5;
		}
		
		private var _pacDizzle:MovieClip;
	}
}