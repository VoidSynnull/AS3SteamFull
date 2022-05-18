package com.poptropica.shellSteps.browser
{
	import com.poptropica.AppConfig;
	import com.poptropica.shellSteps.shared.FileIO;
	
	import game.util.PlatformUtils;
	import game.util.ProxyUtils;

	public class BrowserStepFileIO extends FileIO
	{
		public function BrowserStepFileIO()
		{
			super();
			stepDescription = "Preparing file I/O";
		}
		
		override protected function getContentPrefix():String
		{
			// Only necessary for Browser
			if( PlatformUtils.inBrowser )
			{
				return String("https://" + ProxyUtils.getBrowserHostFromLoaderUrl("https://") + '/game/');
			}
			else
			{
				return super.getContentPrefix();
			}
		}
	}
}