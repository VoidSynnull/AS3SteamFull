package com.poptropica.platformSpecific.mobile.android
{
	import com.poptropica.platformSpecific.mobile.IDeviceCheck;
	import com.poptropica.platformSpecific.mobile.android.deviceInfo.NativeDeviceInfo;
	import com.poptropica.platformSpecific.mobile.android.deviceInfo.NativeDeviceProperties;
	
	import flash.system.Capabilities;
	
	import game.util.PerformanceUtils;
	
	public class AndroidDeviceCheck implements IDeviceCheck
	{
		public function AndroidDeviceCheck()
		{
		}
		
		public function getDevice():String
		{
			loadDeviceInfo();

			return NativeDeviceProperties.PRODUCT_MODEL.value;
		}
		
		public function getDeviceLevel():int
		{
			getDevice();
			
			// try to get dpi from the .prop file on the device
			var dpi:int = int(NativeDeviceProperties.LCD_DENSITY.value);
			
			// otherwise fallback to using System.Capabilities to determine dpi.
			if(dpi == 0)
			{
				dpi = getDPI();
			}
			
			var level:int;
			
			if(dpi >= XXHDPI)
			{
				level = PerformanceUtils.QUALITY_HIGHEST;
			}
			else if(dpi >= XHDPI)
			{
				level = PerformanceUtils.QUALITY_HIGHER;
			}
			else if(dpi >= HDPI)
			{
				level = PerformanceUtils.QUALITY_HIGH;
			}
			else if(dpi >= MDPI)
			{
				level = PerformanceUtils.QUALITY_MEDIUM;
			}
			else if(dpi >= LDPI)
			{
				level = PerformanceUtils.QUALITY_LOW;
			}
			else
			{
				level = PerformanceUtils.QUALITY_LOWEST;
			}
			level = PerformanceUtils.QUALITY_HIGHEST;
			return level;
		}
				
		// there are two possible sources of info for the dpi, with the higher value being more
		//   accurate.
		private function getDPI():int
		{
			var dpi1:int = Capabilities.screenDPI;
			var value:String = unescape(Capabilities.serverString);
			var dpi2:int = value.split("&DP=", 2)[1];
			
			return Math.max(dpi1, dpi2);
		}
		
		// Android detection base on parsing prop file on device.
		// <a href="http://www.funky-monkey.nl/blog/2010/11/11/getting-device-properties-like-os-model-brand-sdk-version-and-cpu-on-air-for-andoid/" rel="nofollow">http://www.funky-monkey.nl/blog/2010/11/11/getting-device-properties-like-os-model-brand-sdk-version-and-cpu-on-air-for-andoid/</a>
		private function loadDeviceInfo():void
		{
			var deviceInfo:NativeDeviceInfo = new NativeDeviceInfo();
			deviceInfo.setDebug(true);
			deviceInfo.parse();
		}
				
		// generalized screen densities (from http://developer.android.com/guide/practices/screens_support.html)
		private static const LDPI:int = 120;
		private static const MDPI:int = 160;
		private static const HDPI:int = 240;
		private static const XHDPI:int = 320;
		private static const XXHDPI:int = 480;
		private static const XXXHDPI:int = 640;
	}
}