package com.poptropica.shellSteps.browser
{
	import com.poptropica.AppConfig;
	import com.poptropica.platformSpecific.browser.BrowserPlatform;
	import com.poptropica.platformSpecific.mobile.MobileNetworkMonitor;
	
	import game.util.PerformanceUtils;
	import game.util.PlatformUtils;

	/**
	 * Build step that determines the platform type.
	 * Should be first step in build sequence and overridden for each type of platform build.
	 * @author umckiba
	 */
	public class BrowserStepSetPlatform extends ShellStep
	{
		public function BrowserStepSetPlatform()
		{
			super();
		}
		
		override protected function build():void
		{
			AppConfig.mobile = false;
			AppConfig.forceMobile = false;
			AppConfig.minimumQuality = PerformanceUtils.QUALITY_MEDIUM;	// NOTE :: This prevents the backdrop from being merged, need more testing on web to allow for lower setting
			this.shellApi.platform = new BrowserPlatform();
			if( PlatformUtils.inBrowser )
			{
				AppConfig.networkAllowed = true;
				AppConfig.storeToExternal = true;
				AppConfig.retrieveFromExternal = true;
				
				// if in Browser we want ads
				AppConfig.adsFromCMS = true;
			}

			shellApi.networkMonitor = new MobileNetworkMonitor();
			MobileNetworkMonitor(shellApi.networkMonitor).shell = shellApi;
			shellApi.networkMonitor.init("http://www.poptropica.com/robots.txt");
			shellApi.networkMonitor.start();
			shellApi.networkMonitor.statusUpdate.addOnce(built);
		}
	}
}