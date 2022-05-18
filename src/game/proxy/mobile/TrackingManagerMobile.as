package game.proxy.mobile
{
	import com.poptropica.interfaces.IThirdPartyTracker;
	
	import engine.Manager;
	
	import game.managers.ScreenManager;
	import game.proxy.TrackingManager;
	
	public class TrackingManagerMobile extends TrackingManager
	{
		public function TrackingManagerMobile()
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
				
				var tpt:IThirdPartyTracker = shellApi.platform.getInstance(IThirdPartyTracker) as IThirdPartyTracker;
				if(tpt)
					thirdPartyTrackers.push(tpt);
			}
		}
	}
}