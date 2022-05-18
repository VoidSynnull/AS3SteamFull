package com.poptropica.platformSpecific.mobile.ios
{
	import com.poptropica.platformSpecific.mobile.IDeviceCheck;
	
	import flash.system.Capabilities;
	
	import game.util.PerformanceUtils;

	public class IosDeviceCheck implements IDeviceCheck
	{
		public function IosDeviceCheck()
		{
		}
		
		public function getDevice():String
		{
			var info:Array = Capabilities.os.split(" ");
			if (info[0] + " " + info[1] != "iPhone OS")
			{
				return UNKNOWN;
			}
			
			// ordered from specific (iPhone1,1) to general (iPhone)
			for each (var device:String in DEVICES)
			{
				if (info[3].indexOf(device) != -1)
				{
					return device;
				}
			}
			return UNKNOWN;
		}
		
		public function getDeviceLevel():int
		{
			var currentDevice:String = getDevice();
			var level:int;
			
			switch(currentDevice)
			{
				case IPHONE_1G :
				case IPHONE_3G :
				case IPHONE_3GS :
				case TOUCH_1G :
				case TOUCH_2G :
				case TOUCH_3G :
				case TOUCH_4G :
				case IPHONE_1G :
				case IPHONE_1G :
				case IPHONE_1G :
					level = PerformanceUtils.QUALITY_LOWEST;
					break;
				
				case IPHONE_4 :
				case IPAD_1 :
					level = PerformanceUtils.QUALITY_LOWER;
					break;
				
				case IPHONE_4S :
				case IPAD_2 :
				case IPAD_3 :
					level = PerformanceUtils.QUALITY_LOW;
					break;
				
				/*
				// Downgrading IPAD_3 performance
				case IPAD_3 :
				level = PerformanceUtils.QUALITY_MEDIUM;
				break;
				*/
				
				case IPHONE_5PLUS :
				case TOUCH_5PLUS :
				case IPAD_4PLUS :
				case UNKNOWN :
				default :
					level = PerformanceUtils.QUALITY_HIGHEST;
					break;
			}
			
			return(PerformanceUtils.QUALITY_HIGHEST);
		}
		
		//device list, from http://www.adobe.com/devnet/air/articles/multiple-screen-sizes.html
		private static const DEVICES:Array = [IPHONE_1G, IPHONE_3G, IPHONE_3GS,
			IPHONE_4, IPHONE_4S, IPHONE_5PLUS, IPAD_1, IPAD_2, IPAD_3, IPAD_4PLUS,
			TOUCH_1G, TOUCH_2G, TOUCH_3G, TOUCH_4G, TOUCH_5PLUS];
		
		public static const IPHONE_1G:String = "iPhone1,1"; // first gen is 1,1
		public static const IPHONE_3G:String = "iPhone1"; 	// second gen is 1,2
		public static const IPHONE_3GS:String = "iPhone2"; 	// third gen is 2,1
		public static const IPHONE_4:String = "iPhone3"; 	// normal:3,1 verizon:3,3
		public static const IPHONE_4S:String = "iPhone4"; 	// 4S is 4,1
		public static const IPHONE_5PLUS:String = "iPhone";
		public static const TOUCH_1G:String = "iPod1,1";
		public static const TOUCH_2G:String = "iPod2,1";
		public static const TOUCH_3G:String = "iPod3,1";
		public static const TOUCH_4G:String = "iPod4,1";
		public static const TOUCH_5PLUS:String = "iPod";
		public static const IPAD_1:String = "iPad1"; 		// iPad1 is 1,1
		public static const IPAD_2:String = "iPad2"; 		// wifi:2,1 gsm:2,2 cdma:2,3
		public static const IPAD_3:String = "iPad3";
		public static const IPAD_4PLUS:String = "iPad";
		public static const UNKNOWN:String = "unknown";
	}
}