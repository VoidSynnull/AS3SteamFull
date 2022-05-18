package com.poptropica.shellSteps.shared
{
	import com.poptropica.Assert;
	
	import flash.events.UncaughtErrorEvent;
	
	import game.proxy.FENErrorLogger;

	public class SetupErrorHandling extends ShellStep
	{
		public function SetupErrorHandling()
		{
			super();
		}
		
		override protected function build():void
		{
			Assert.errorThrown.add(handleErrorThrown);
			
			// Add global error capture.
			super.shell.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, uncaughtErrorHandler);
			shellApi.errorLogger = new FENErrorLogger();
			super.built();
		}
		
		private function uncaughtErrorHandler(e:UncaughtErrorEvent):void 
		{
			trace("SetupErrorHandling::uncaughtErrorHandler()", e);
			// Do we really need all these checks any more? 
			//if(e.error && e.error.hasOwnProperty("errorID") && e.error.errorID)
			if (e.error) {
				trace("enclosed error", e.error);
				var msg:String = e.error.getStackTrace();
				if (msg) {
					shellApi.errorLogger.log(msg);
				} else trace("no stacktrace");
			} else trace("no error in event");
		}
		
		protected function handleErrorThrown(message:String, trackingChoice:String = null):void
		{
			if(trackingChoice != null)
			{
				super.shellApi.track("ErrorThrown", message, trackingChoice);
			}
		}
	}
}