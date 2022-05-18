package com.poptropica.shells.browser.steps
{
	import flash.display.DisplayObject;

	public class BrowserStepShowSplashScreen extends ShellStep
	{
		public function BrowserStepShowSplashScreen()
		{
			super();
		}
		
		protected override function build():void
		{
			shell.stepChanged.add(updateProgressBar);
			shell.complete.addOnce(removeSplashScreen);
		}
		
		private function updateProgressBar(step:ShellStep):void
		{
			
		}
		
		private function removeSplashScreen(shell:Shell):void
		{
			trace("BrowserStepShowSplashScreen : removing splash screen.");
			for(var i:int = shell.parent.numChildren-1; i >= 0; i--)
			{
				var child:DisplayObject = shell.parent.getChildAt(i);
				trace("Shell -> Parent -> Child -> Name : " + child.name);
				if(child != shell)
				{
					shell.removeChild(child);
				}
			}
		}
	}
}