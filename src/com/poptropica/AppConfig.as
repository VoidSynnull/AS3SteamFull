package com.poptropica
{
	import game.data.PlatformType;
	import game.util.PerformanceUtils;

	/**
	 * Central class that stores application wide settings.
	 * Shoudl allow for developers to adjust settings to accomodate debug scenarios,
	 * while also allowing for Jenkins builds to manual override the settings based on build type.
	 * @author umckiba
	 * 
	 */
	public class AppConfig
	{
		/**
		 * ATTENTION : These flags should not be adjusted by the developers, to set flags for testing use DebugConfig 
		 */
		public function AppConfig()
		{
		}
		
		// APLLICATION SETTINGS //
		
		/** Determines if application is a production build, when in production various debug features are not active and different hosts are used. */
		public static var production:Boolean 			= true;
		
		/** Flag for running as a mobile application */
		public static var mobile:Boolean             	= false;
		
		/** Flag for running as Android application */
		public static var isAndroid:Boolean             = false;

		/** Determines is in app purchase is active */
		public static var iapOn:Boolean 				= false;
		
		/** Determines if network connection is allowed */
		public static var networkAllowed:Boolean 		= true;		
		
		/** Determines if data should be stored externally (to server or site specific LSO) */
		public static var storeToExternal:Boolean 		= false;
		
		/** Determines if data can be retrived from externally data sources (from server or site specific LSO) */
		public static var retrieveFromExternal:Boolean 	= false;
		
		/** Version number of the app, should reflect this format: 0.0.0 */
		public static var appVersionNumber:String;
		
		/** Host for assets, will vary based on production test environment, ultimately set by build process */
		public static var assetHost:String;		
		
		/** 
		 * Version of the app including app version, kernel version & build info. 
		 * Should reflect this format: 0.0.0 build info <0.0.0>
		 */
		public static var appVersionString:String;
		
		/** Flag set to true when app detects a version update */
		public static var appUpdated:Boolean = false;
		
		/** Version number of the zips used, should be same as <code>appVersionNumber</code> */
		public static var zipfilesVersion:String = "0.0.0";
		
		/** Multiplayer zone to log into for this client version */
		public static var multiplayerZone:String = "Poptropica_0218";
		
		/** Minimum possible quality setting for platform, on browser we want to increase this */
		public static var minimumQuality:int = PerformanceUtils.QUALITY_LOWEST;
		
		/** Time limit in milliseconds for secondary content (in island ads) to take to load & decompress */
		public static var timeLimitForSecondaryContent:int = 7000;	// 7 seconds
		
		/**
		 * applicationUrl is determined by the Flash Player based on it's context.
		 * applicationUrl starts with app:/  when running on Desktop or Mobile
		 * applicationUrl starts with https:// when running in Browser
		 */
		public static var applicationUrl:String = "https://";

		/** 
		 * Type of device application is running on. 
		 * Acceptable types strings are found in <code>PlatformType</code> and include:
		 * PlatformType.MOBILE, PlatformType.TABLET, PlatformType.DESKTOP
		 * NOTE :: Overridden by forceMobile.
		 */
		private static var _platformType:String;
		public static function set platformType(platformType:String):void { _platformType = platformType; }
		public static function get platformType():String
		{
			if(AppConfig.forceMobile) { return(PlatformType.MOBILE); }
			return( _platformType );
		}
		
		public static var mobileOS:String;
		public static const ANDROID:String = "android";
		public static const FIRE_OS:String = 'amazon';
		public static const IOS:String = "iOS";
		
		
		// DEBUG SPECIFC //
		
		/** Determines if debugging is active, used in a variety of instances to provide additional information and transparency during development. */
		public static var debug:Boolean 				= false;
		
		/** description */
		public static var verifyPathInManifest:Boolean 	= false;
		
		/** Used to force application into running certain mobile features, used for testing on desktop. */
		public static var forceMobile:Boolean 			= false;
		
		/** Used to force application into running certain browser features, used for testing on desktop. */
		public static var forceBrowser:Boolean 			= false;
		
		/** Don't use DLC, useful when trying to test mobile aspects that don't involve DLC */
		public static var ignoreDLC:Boolean 			= false;
		
		/** Used to automatically reset user data on game start up, should only be used as a debug tool */
		public static var resetData:Boolean 			= false;
		
		/** Used to load files from the server that are missing from the device on mobile. */
		public static var loadMissingPartsFromServer:Boolean = true;

		/** Used to prevent the dev console from displaying messages about missing content */
		public static var suppressLoadErrorMessages:Boolean = false;

		/** Set verbosity threshold */
		public static var logLevel:uint;
		
		// AD SPECIFIC //
		
		/** Determines whether ads are active or not */
		public static var adsActive:Boolean 	= false;
		
		/** If true pulls active campaigns from CMS **/
		public static var adsFromCMS:Boolean 	= false;
		
		
		
				
		// TODO :: Add Modes, so that a mode can be passed that sets flags to meet mode needs.
		// for example DEBUG_MOBILE_ON_DESKTOP, would allow you to test mobile functionality on desktop
		// NOTE :: This mode would likely be defined within DebugConfig
		//public static setMode():void
	}
}
