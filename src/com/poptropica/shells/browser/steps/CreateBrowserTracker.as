package com.poptropica.shells.browser.steps
{
	import com.poptropica.AppConfig;
	
	import game.proxy.ITrackingManager;
	import game.proxy.browser.TrackingManagerWeb;
	import game.util.PlatformUtils;

	public class CreateBrowserTracker extends ShellStep
	{
		public function CreateBrowserTracker()
		{
			super();
			stepDescription = "Creating tracker";
		}
		
		override protected function build():void
		{
			shellApi.addManager( new TrackingManagerWeb(), ITrackingManager );
			shellApi.errorLogger.init(shellApi.siteProxy.gameHost, shellApi.profileManager.active.login, PlatformUtils.platformDescription, AppConfig.appVersionString);
			built();
		}
	}
}