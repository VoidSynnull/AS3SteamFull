package com.poptropica.shells.mobile.android.steps
{
	import com.poptropica.AppConfig;
	import com.poptropica.platformSpecific.android.AmazonPlatform;
	import com.poptropica.platformSpecific.mobile.MobileNetworkMonitor;
	
	import flash.utils.setTimeout;

	public class AmazonAndroidShellSetPlatformStep extends ShellStep
	{
		public function AmazonAndroidShellSetPlatformStep()
		{
			super();
		}
		
		override protected function build():void
		{
			AppConfig.mobile = true;
			AppConfig.forceMobile = false;
			AppConfig.mobileOS = AppConfig.FIRE_OS;
			shellApi.platform = new AmazonPlatform();
			
			//Loads network Monitor into memory and starts it with our live url.
			//Calling shellApi.networkAvailable will reach into this object and return a Boolean.
			shellApi.networkMonitor = new MobileNetworkMonitor();
			shellApi.networkMonitor.init("http://www.poptropica.com/robots.txt");
			shellApi.networkMonitor.start();
			shellApi.networkMonitor.statusUpdate.addOnce(built);
		}		
	}
}
