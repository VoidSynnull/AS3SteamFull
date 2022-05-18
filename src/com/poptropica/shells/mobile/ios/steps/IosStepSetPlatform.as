package com.poptropica.shells.mobile.ios.steps
{
	import com.poptropica.AppConfig;
	import com.poptropica.platformSpecific.ios.IosPlatform;
	import com.poptropica.platformSpecific.mobile.MobileNetworkMonitor;

	import flash.utils.setTimeout;

	public class IosStepSetPlatform extends ShellStep
	{
		public function IosStepSetPlatform()
		{
			super();
		}

		override protected function build():void
		{
			AppConfig.mobile = true;
			AppConfig.mobileOS = AppConfig.IOS;
			shellApi.platform = new IosPlatform();
			
			//Loads network Monitor into memory and starts it with our live url.
			//Calling shellApi.networkAvailable will reach into this object and return a Boolean.
			shellApi.networkMonitor = new MobileNetworkMonitor();
			
			shellApi.networkMonitor.init("http://www.poptropica.com/robots.txt");
			shellApi.networkMonitor.start();
			shellApi.networkMonitor.statusUpdate.addOnce(built);
		}

	}

}
