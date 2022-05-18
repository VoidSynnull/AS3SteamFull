package com.poptropica.shells.mobile.android.steps
{
	import com.poptropica.AppConfig;
	import com.poptropica.platformSpecific.android.AndroidPlatform;
	import com.poptropica.platformSpecific.mobile.MobileNetworkMonitor;

	public class AndroidStepSetPlatform extends ShellStep
	{
		public function AndroidStepSetPlatform()
		{
			super();
		}
		
		override protected function build():void
		{
			AppConfig.mobile = true;
			AppConfig.mobileOS = AppConfig.ANDROID;
			//AppConfig.forceMobile = false;
			shellApi.platform = new AndroidPlatform();
			
			//Loads network Monitor into memory and starts it with our live url.
			//Calling shellApi.networkAvailable will reach into this object and return a Boolean.
			shellApi.networkMonitor = new MobileNetworkMonitor();
			shellApi.networkMonitor.init("http://www.poptropica.com/robots.txt");
			shellApi.networkMonitor.start();
			shellApi.networkMonitor.statusUpdate.addOnce(built);
		}

	}

}
