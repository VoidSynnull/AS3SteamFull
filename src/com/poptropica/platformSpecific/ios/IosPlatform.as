package com.poptropica.platformSpecific.ios
{
	import com.poptropica.AppConfig;
	import com.poptropica.interfaces.INativeAppMethods;
	import com.poptropica.interfaces.INativeFileMethods;
	import com.poptropica.interfaces.INetworkMonitor;
	import com.poptropica.interfaces.IProductStore;
	import com.poptropica.interfaces.IThirdPartyTracker;
	import com.poptropica.platformSpecific.GoogleAnalyticsTracker;
	import com.poptropica.platformSpecific.Platform;
	import com.poptropica.platformSpecific.mobile.IDeviceCheck;
	import com.poptropica.platformSpecific.mobile.ios.IosDeviceCheck;
	import com.poptropica.platformSpecific.mobile.ios.IosNetworkMonitor;
	import com.poptropica.platformSpecific.nativeClasses.NativeAppMethods;
	import com.poptropica.platformSpecific.nativeClasses.NativeFileMethods;
	
	import org.assetloader.core.ILoader;
	import org.assetloader.loaders.IosSWFLoader;
	import org.assetloader.loaders.SWFLoader;
	
	public class IosPlatform extends Platform
	{
		public function IosPlatform()
		{
			super();	
			
			//Air class helper functions for FileManager
			_classes[INativeFileMethods] = NativeFileMethods;
			// AIR class helper functions for mobile OS
			_classes[INativeAppMethods] = NativeAppMethods;

			//new loader package
			_classes[ILoader] = ( AppConfig.ignoreDLC ) ? SWFLoader : IosSWFLoader;
			
			//Google Analytics
			_classes[IThirdPartyTracker] = GoogleAnalyticsTracker;
			
			//Product Store
			_classes[IProductStore] = IosProductStore;
			
			//Network connectivity polling.
			_classes[INetworkMonitor] = IosNetworkMonitor;
			
			// platform specific device determination.
			_classes[IDeviceCheck] = IosDeviceCheck;
							
			trace(this, "ios");
		}
	}
}
