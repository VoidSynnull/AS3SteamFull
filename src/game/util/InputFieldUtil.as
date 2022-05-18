package game.util
{
	import flash.display.DisplayObjectContainer;
	import flash.events.FocusEvent;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	
	import engine.ShellApi;
	import engine.util.Command;
	
	import fl.motion.easing.Quadratic;
	import fl.transitions.Tween;
	

	public class InputFieldUtil
	{
		private static var tween:Tween;
		
		private static var currentTarget:Object;
		
		public function InputFieldUtil()
		{
			
		}
		
		public static function setUpFieldToScroll(tf:TextField, shellApi:ShellApi):void
		{
			if(PlatformUtils.isAndroid)// ios works
			{
				var obj:Object = new Object();
				obj.shellApi = shellApi;
				obj.origin = shellApi.screenManager.container.y;
				tf.addEventListener(FocusEvent.FOCUS_IN, Command.create(onSoftKeyboardActivate, obj));
				tf.addEventListener(FocusEvent.FOCUS_OUT, Command.create(onSoftKeyboardDeactivate, obj));
			}
		}
		
		protected static function onSoftKeyboardDeactivate(event:FocusEvent, obj:Object):void
		{
			var tf:TextField = event.target as TextField;
			var tweenContainer:DisplayObjectContainer = obj.shellApi.screenManager.container;
			trace(tf.name + " deactivate requested " + currentTarget.name + " : " + tweenContainer.y);
			if(tweenContainer.y != obj.origin)
			{
				if(currentTarget == tf)
				{
					if(tween)
					{
						tween.stop();
					}
					tween = new Tween(tweenContainer,"y", Quadratic.easeOut,tweenContainer.y,obj.origin,.5,true);
					tween.FPS = 30;
					tween.start();
				}
			}
		}
		
		protected static function onSoftKeyboardActivate(event:FocusEvent, obj:Object):void
		{
			var tf:TextField = event.target as TextField;
			currentTarget = tf;
			var globalLocation:Rectangle = tf.getBounds(tf.stage);
			var shellApi:ShellApi = obj.shellApi;
			var delta:Number = shellApi.viewportHeight/2- globalLocation.bottom;
			
			var tweenContainer:DisplayObjectContainer = shellApi.screenManager.container;
			
			trace("activate requested from " + tf.name + ". delta: " + delta + " y: " + tweenContainer.y + " origin: " + obj.origin);
			
			if(delta < 0 || tweenContainer.y + delta < obj.origin)
			{
				if(tween)
					tween.stop();
				
				tf.requestSoftKeyboard();
				
				tween = new Tween(tweenContainer,"y", Quadratic.easeOut,tweenContainer.y,tweenContainer.y + delta,.5,true);
				tween.FPS = 30;
				tween.start();
			}
		}
	}
}