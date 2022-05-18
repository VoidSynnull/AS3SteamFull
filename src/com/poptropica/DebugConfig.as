package com.poptropica
{
	import game.util.PerformanceUtils;

	public class DebugConfig
	{
		public function DebugConfig()
		{
		}
		
		public static function setFlags( mode:String = "" ):void
		{
			// Test Commit
			// DEBUG SPECIFC //
			AppConfig.debug = false;
			AppConfig.verifyPathInManifest = false;
			AppConfig.forceBrowser = true;
			AppConfig.forceMobile = false;
			AppConfig.ignoreDLC = true;
			AppConfig.resetData = false;
			AppConfig.production = true;

			// DLC SPECIFIC //
			AppConfig.iapOn = false;
			AppConfig.networkAllowed = true;
			
			// AD SPECIFIC //
			AppConfig.adsActive = true;
			AppConfig.adsFromCMS = false;
			
			// set flags by mode
			switch(mode)
			{
				case MODE_DESKTOP:
				{
					break;
				}
					
				case MODE_DESKTOP_MOBILE:
				{
					AppConfig.forceMobile = true;
					AppConfig.ignoreDLC = true;
					break;
				}
					
				case MODE_DESKTOP_MOBILE_DLC:
				{
					AppConfig.forceMobile = true;
					AppConfig.ignoreDLC = false;
					break;
				}
					
				case MODE_MOBILE:
				{
					AppConfig.forceMobile = false;
					AppConfig.verifyPathInManifest = false;
					AppConfig.ignoreDLC = false;
					break;
				}
					
				case MODE_BROWSER:
				{
					// NOTE :: For now on browser we keep min quality her to prevent flattening backdrop
					AppConfig.minimumQuality = PerformanceUtils.QUALITY_MEDIUM;
					AppConfig.verifyPathInManifest = false;
					AppConfig.forceBrowser = false;
					break;
				}
					
				default:
				{
					break;
				}
			}
		}
		
		
		public static var MODE_DESKTOP:String = "desktop";
		public static var MODE_DESKTOP_MOBILE_DLC:String = "desktop_mobile_dlc";
		public static var MODE_DESKTOP_MOBILE:String = "desktop_mobile";
		public static var MODE_MOBILE:String = "mobile";
		public static var MODE_BROWSER:String = "browser";
	}
}