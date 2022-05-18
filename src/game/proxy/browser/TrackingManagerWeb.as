package game.proxy.browser
{
	import com.poptropica.interfaces.IThirdPartyTracker;
	
	import engine.Manager;
	
	import game.managers.ScreenManager;
	import game.proxy.TrackingManager;
	
	public class TrackingManagerWeb extends TrackingManager
	{
		public function TrackingManagerWeb()
		{}
		
		override protected function construct():void
		{
			super.construct();
		}
		
		override protected function getScreenManager(manager:Manager):void
		{
			if (manager is ScreenManager)
			{
				// TODO :: Seems odd we need to get the 3rd party tracker from the ScreenManager? - bard
				this.shellApi.managerAdded.remove(this.getScreenManager);
				
				thirdPartyTrackers.push(shellApi.platform.getInstance(IThirdPartyTracker, [ScreenManager(manager).devToolsContainer]) as IThirdPartyTracker);
			}
		}
	}
}