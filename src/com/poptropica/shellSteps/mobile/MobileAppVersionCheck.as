package com.poptropica.shellSteps.mobile
{
	import com.poptropica.AppConfig;
	
	import game.util.DataUtils;

	public class MobileAppVersionCheck extends ShellStep
	{
		public function MobileAppVersionCheck()
		{
			super();
			stepDescription = "Checking version";
		}
		
		override protected function build():void
		{
			var appVersions:Array = super.shellApi.profileManager.globalData.appVersions;
			
			if(appVersions == null)
			{
				appVersions = super.shellApi.profileManager.globalData.appVersions = new Array();
				super.shellApi.profileManager.saveGlobalData();
			}
			
			var currentVersion:String = String(AppConfig.appVersionString);
			
			if(!DataUtils.isNull(currentVersion))
			{
				var lastStoredVersion:String;
				
				if(appVersions.length > 0)
				{
					lastStoredVersion = appVersions[appVersions.length - 1];
				}
				
				if(currentVersion != lastStoredVersion)
				{
					// if there is a previous version stored that isn't equal to the current, than the app has just been updated.
					AppConfig.appUpdated = true; 
					
					// store the current app version in the version history.
					appVersions.push(currentVersion);
					super.shellApi.profileManager.saveGlobalData();
				}
			}

			built();
		}
	}
}