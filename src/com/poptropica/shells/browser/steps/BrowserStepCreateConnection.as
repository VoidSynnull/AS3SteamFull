package com.poptropica.shells.browser.steps
{
	import com.poptropica.shellSteps.shared.CreateConnection;
	
	import game.data.CommunicationData;
	import game.proxy.ILegacyDataManager;
	import game.proxy.browser.DataStoreProxyPopBrowser;
	import game.proxy.browser.LegacyDataManager;
	import game.util.PlatformUtils;

	/**
	 * Build step that loads XML file specifying hosts urls and php scripts, 
	 * then uses that data to create connection to secure host.
	 * @author umckiba
	 * 
	 */
	public class BrowserStepCreateConnection extends CreateConnection
	{
		public function BrowserStepCreateConnection()
		{
			super();
			stepDescription = "Establishing communications";
			super.dataStoreClass = DataStoreProxyPopBrowser;
		}

		override protected function createConnection( commConfigXml:XML = null ):void
		{
			super.createConnection(commConfigXml);
			
			// create manager to communicate with AS2 LSO
			// this is mostly necessary for guest users, since they cannot communicate with the backend. 
			// With server access everything has to be stored in the LSO and transferred to the AS2 LSO, 
			// so that when a guest creates an account that data is there to be sent to the backend
			shellApi.addManager(new LegacyDataManager(), ILegacyDataManager);
		}
		
		/**
		 * Setup game url for browser
		 * @param commnData
		 * @param commConfigXML
		 */
		override protected function setupHosts( commData:CommunicationData, commConfigXML:XML ):void
		{
			// if NOT in Browser, get hosts from communication config file
			// if IS in Browser derive gameHost from current application url, on browser only a single host is necessary	
			if( !PlatformUtils.inBrowser )	
			{
				// only necessary for local testing
				super.setupHosts(commData, commConfigXML);
			}
			else	
			{
				commData.deriveBrowserHost();
				commData.fileHost = commData.staticHost = commData.gameHost;
			}
		}
	}
}