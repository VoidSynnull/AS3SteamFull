package com.poptropica.platformSpecific.android
{
	
	import com.poptropica.interfaces.INativeAppMethods;
	import com.poptropica.interfaces.INativeFileMethods;
	import com.poptropica.interfaces.INetworkMonitor;
	//import com.poptropica.interfaces.IProductStore;
	import com.poptropica.interfaces.IThirdPartyTracker;
	import com.poptropica.platformSpecific.GoogleAnalyticsTracker;
	import com.poptropica.platformSpecific.Platform;
	import com.poptropica.platformSpecific.mobile.IDeviceCheck;
	import com.poptropica.platformSpecific.mobile.android.AndroidDeviceCheck;
	import com.poptropica.platformSpecific.mobile.android.AndroidNetworkMonitor;
	import com.poptropica.platformSpecific.nativeClasses.NativeAppMethods;
	import com.poptropica.platformSpecific.nativeClasses.NativeFileMethods;
	
	import org.assetloader.core.ILoader;
	import org.assetloader.loaders.SWFLoader;
	
	public class AmazonPlatform extends Platform
	{
		public function AmazonPlatform()
		{
			super();
			
			//Air class helper functions for FileManager
			_classes[INativeFileMethods]	= NativeFileMethods;
			// AIR class helper functions for mobile OS
			_classes[INativeAppMethods]		= NativeAppMethods;

			_classes[ILoader]				= SWFLoader;
			//GA
			//_classes[IThirdPartyTracker]	= GoogleAnalyticsTracker;
			
			//Setting this for mobile
			_classes[INetworkMonitor]		= AndroidNetworkMonitor;
			//_classes[IProductStore]			= AmazonProductStore;
			// platform specific device determination.
			_classes[IDeviceCheck]			= AndroidDeviceCheck;
							
			trace(this, "amazon");
		}
	}
}
