package com.poptropica.shells.mobile.steps
{
	import com.poptropica.shellSteps.shared.CreateConnection;
	
	import game.managers.WallClock;
	import game.proxy.IDataStore2;
	import game.proxy.mobile.DataStoreProxyPopMobile;

	public class MobileStepCreateConnection extends CreateConnection
	{
		private var _getPrefixTimer:WallClock;
		
		// sets up the siteProxy
		public function MobileStepCreateConnection()
		{
			super();
			stepDescription = "Establishing communications";
		}
		
		// TODO :: Want to clean this up so we don't need the WallClock. -bard
		override protected function build():void
		{
			// load comm.xml file
			super.loadConnectionConfig();
		}
		
		/**
		 * Attempt connection to secrure host.
		 * Can't guarantee a connection on mobile, so a time out is included in case a connection cannot be made. 
		 * @param commConfigXml
		 */
		override protected function createConnection( commConfigXml:XML = null ):void
		{
			var serverProxy:DataStoreProxyPopMobile = shellApi.addManager(new DataStoreProxyPopMobile(), IDataStore2) as DataStoreProxyPopMobile;
			
			if( commConfigXml != null )
			{
				// TODO :: Possible we could check on this in a later step, making better use of the wait time? - bard
				
				// give this call 5 seconds to complete before we give up.
				_getPrefixTimer = new WallClock(5);
				_getPrefixTimer.chime.add(getSecureHostTimedOut);
				_getPrefixTimer.start();
				
				// when ServerProxyMobile is initialized it attempts to contact the server to retrieve a secure host
				serverProxy.AMFPHPGateWayReady.addOnce(getSecureHostResponce);
				serverProxy.init( super.createCommunicationData(commConfigXml) );
			}
			else
			{
				// TODO :: How should be handle this? Can we recover? - bard
				trace( "Error :: MobileStep : MobileStepCreateConnection : communication config XML failed to laod." );
			}
		}
		
		private function getSecureHostResponce():void
		{
			// clean up timer
			if (_getPrefixTimer != null) 
			{
				_getPrefixTimer.stop();
				_getPrefixTimer.chime.removeAll();
				_getPrefixTimer = null;
			}
			built();
		}
		
		/**
		 * Connection was not made within specified delay 
		 */
		private function getSecureHostTimedOut():void
		{
			// clean up timer
			_getPrefixTimer.chime.removeAll();
			_getPrefixTimer = null;
			// clean up signal
			var siteProxy:IDataStore2 = shellApi.siteProxy;
			siteProxy.AMFPHPGateWayReady.removeAll();
			
			// use a default url
			siteProxy.useDefaultSecureURL();
			built();
		}
	}
}