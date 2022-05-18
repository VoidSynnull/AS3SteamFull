package game.util
{
	import com.poptropica.AppConfig;
	
	import flash.system.Capabilities;

	public class PlatformUtils
	{
		/**
		 * Determines if appplication is running on a mobile device (phone, tablet).
		 * Essentially checks for the mobile flag. 
		 * NOTE :: Overridden by forceMobile.
		 * @return 
		 */
		public static function get isMobileOS():Boolean
		{
			if(AppConfig.forceMobile)
			{
				return(true);
			}

			return(AppConfig.mobile);
		}
		
		/**
		 * Determines if appplication is running on Android.
		 * @return 
		 */
		public static function get isAndroid():Boolean
		{
			if(PlatformUtils.isMobileOS)
			{
				return (AppConfig.mobileOS == AppConfig.ANDROID);
			}
			
			return false;
		}
		
		/**
		 * Determines if appplication is running on iOS.
		 * @return 
		 */
		public static function get isIOS():Boolean
		{
			if(PlatformUtils.isMobileOS)
			{
				return (AppConfig.mobileOS == AppConfig.IOS);
			}
			
			return false;
		}
		
		/**
		 * Determiens if application is running on a desktop computer.
		 * Essentially checks for the absence of the mobile flag. 
		 * NOTE :: Overridden by forceMobile.
		 * @return 
		 * 
		 */
		public static function get isDesktop():Boolean
		{
			if(AppConfig.forceMobile)
			{
				return(false);
			}
			
			return(!AppConfig.mobile);
		}

		public static function get platformDescription():String
		{
			var description:String = AppConfig.platformType;

			if (description) {
				switch (AppConfig.mobileOS) {
					case AppConfig.ANDROID:
					case AppConfig.FIRE_OS:
						description += '-' + AppConfig.mobileOS;
						break;
					default:
						break;
				}
			}
			return description;
		}

		/**
		 * Determines if appplication is running within a browser.
		 * For reference when using Capabilities.playerType:
		 * "ActiveX" for the Flash Player ActiveX control used by Microsoft Internet Explorer
		 * "PlugIn" for the Flash Player browser plug-in (and for SWF content loaded by an HTML page in an AIR application)
		 * @return 
		 */
		public static function get inBrowser():Boolean
		{
			return ("PlugIn" == Capabilities.playerType) || ("ActiveX" == Capabilities.playerType);
		}
	}
}

