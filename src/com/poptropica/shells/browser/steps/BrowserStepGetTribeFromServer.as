package com.poptropica.shells.browser.steps
{
	import com.poptropica.AppConfig;
	
	import game.data.profile.ProfileData;
	import game.util.TribeUtils;

	public class BrowserStepGetTribeFromServer extends ShellStep
	{
		/**
		 * Retrieve tribe from server if it has not yet been defined
		 */
		public function BrowserStepGetTribeFromServer()
		{
			super();
			stepDescription = "Setting user tribe";
		}
		
		override protected function build():void
		{
			var currentProfile:ProfileData = shellApi.profileManager.active;
			trace("BrowserStepGetTribeFromServer : tribe data : " + currentProfile.tribeData);
			
			// check if tribe has already been assigned, if not check server			
			if ( !currentProfile.isGuest && currentProfile.tribeData == null ) 
			{
				if( shellApi.networkAvailable() && AppConfig.retrieveFromExternal )
				{	
					trace( "Shell :: BrowserStepGetTribeFromServer : tribe data not found in lso, check database.");
					shellApi.getUserField( TribeUtils.TRIBE_FIELD, "", this.onTribeReturned, true );
					return;
				}
				else
				{
					trace("BrowserShell :: BrowserStepGetTribeFromServer :: network NOT available, cannot retrive tribe data from server.");
				}
			} 

			built();
		}
		
		private function onTribeReturned( serverTribeValue:* ):void
		{
			trace( "Shell :: BrowserStepGetTribeFromServer : tribe pulled from database: " + serverTribeValue );
			if(serverTribeValue != null)
			{
				shellApi.profileManager.active.tribeData = TribeUtils.getTribeDataByIndex( serverTribeValue );
			}
			built();
		}
	}
}