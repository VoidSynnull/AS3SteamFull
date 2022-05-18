package com.poptropica.platformSpecific.android
{
	import com.poptropica.AppConfig;
	import com.poptropica.interfaces.INativeAppMethods;
	import com.poptropica.interfaces.INativeFileMethods;
	import com.poptropica.interfaces.INetworkMonitor;
	import com.poptropica.interfaces.IProductStore;
	import com.poptropica.interfaces.IThirdPartyTracker;
	//import com.poptropica.platformSpecific.FirebaseTracker;
	//import com.poptropica.platformSpecific.GoogleAnalyticsTracker;
	import com.poptropica.platformSpecific.Platform;
	import com.poptropica.platformSpecific.mobile.IDeviceCheck;
	import com.poptropica.platformSpecific.mobile.android.AndroidDeviceCheck;
	import com.poptropica.platformSpecific.mobile.android.AndroidNetworkMonitor;
	import com.poptropica.platformSpecific.nativeClasses.NativeAppMethods;
	import com.poptropica.platformSpecific.nativeClasses.NativeFileMethods;
	
	import org.assetloader.core.ILoader;
	import org.assetloader.loaders.AndroidSWFLoader;
	import org.assetloader.loaders.SWFLoader;
	
	public class AndroidPlatform extends Platform
	{
		public function AndroidPlatform()
		{
			super();
			
			//Air class helper functions for FileManager
			_classes[INativeFileMethods] = NativeFileMethods;
			// AIR class helper functions for mobile OS
			_classes[INativeAppMethods] = NativeAppMethods;
			
			//new loader package
			_classes[ILoader] = ( AppConfig.ignoreDLC ) ? SWFLoader : AndroidSWFLoader;
			
			//Google Analytics
			//_classes[IThirdPartyTracker] = GoogleAnalyticsTracker;
			//_classes[IThirdPartyTracker] = FirebaseTracker;
			
			//Product Store
			_classes[IProductStore] = AndroidProductStore;
			
			//Network connectivity polling
			_classes[INetworkMonitor] = AndroidNetworkMonitor;
			
			// platform specific device determination.
			_classes[IDeviceCheck] = AndroidDeviceCheck;
							
			trace(this, "android");
		}
	}
}
