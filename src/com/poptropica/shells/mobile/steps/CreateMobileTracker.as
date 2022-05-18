package com.poptropica.shells.mobile.steps
{
	import com.poptropica.AppConfig;
	
	import game.proxy.ITrackingManager;
	import game.proxy.mobile.TrackingManagerMobile;
	import game.util.PlatformUtils;

	public class CreateMobileTracker extends ShellStep
	{
		public function CreateMobileTracker()
		{
			super();
			stepDescription = "Creating tracker";
		}
		
		override protected function build():void
		{
			shellApi.addManager( new TrackingManagerMobile(), ITrackingManager );
			shellApi.errorLogger.init(shellApi.siteProxy.gameHost, shellApi.profileManager.active.login, PlatformUtils.platformDescription, AppConfig.appVersionString);
			built();
		}
	}
}