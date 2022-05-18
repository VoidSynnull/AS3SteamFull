package com.poptropica.shellSteps.shared
{
	import com.poptropica.AppConfig;
	
	import engine.managers.FileManager;
	
	import game.data.CommunicationData;
	import game.proxy.DataStoreProxy;
	import game.proxy.IDataStore2;

	/**
	 * Build step that loads XML file specifying hosts urls and php scripts, 
	 * then uses that data to create connection to secure host.
	 * @author umckiba
	 * 
	 */
	public class CreateConnection extends ShellStep
	{
		protected const DEFAULT_CONFIG_PATH:String = "game/comm.xml";
		protected var dataStoreClass:Class = DataStoreProxy;

		/**
		 * Build step that loads XML file specifying hosts urls and php scripts.
		 */
		public function CreateConnection()
		{
			super();
		}
		
		override protected function build():void
		{ AppConfig.applicationUrl = "https://";
			trace("CreateConnection Step :: application url : " + AppConfig.applicationUrl);
			//trace("CreateConnection Step :: is test Server :  " + ProxyUtils.isTestServer(AppConfig.applicationUrl));
			
			loadConnectionConfig( DEFAULT_CONFIG_PATH );
		}
		
		/**
		 * Loads file containing communication configuration
		 * @param configPath
		 */
		protected function loadConnectionConfig( configPath:String = "" ):void
		{
			// NOTE : Currently browser and mobile use the same file
			if( configPath == "" )	{ configPath = this.DEFAULT_CONFIG_PATH; }
			var fileManager:FileManager = FileManager(this.shellApi.getManager(FileManager));
			fileManager.cacheFile(fileManager.dataPrefix + configPath, createConnection);
		}
		
		/**
		 * Called once communication file has loaded, sets up the external communication proxy
		 * @param commConfigXml - XML file containing communication configuration
		 */
		protected function createConnection( commConfigXml:XML = null ):void
		{
			var siteProxy:IDataStore2 = shellApi.addManager(new dataStoreClass(), IDataStore2) as IDataStore2;

			if( commConfigXml != null )
			{
				// TODO :: On Browser what happens if this connection fails?  Doesn't appear to be any handling for that scenario. - bard
				// when ServerProxyMobile is initialized it attempts to contact the server to retrieve a secure host
				siteProxy.AMFPHPGateWayReady.addOnce(built);
				siteProxy.init( createCommunicationData(commConfigXml) );	// establish secure host
			}
			else
			{
				trace( "Error :: CreateConnection Step : communication configuration file failed to load." );
			}
		}
		
		/**
		 * Create CommunicationData class whose setup requires the communication configuration XML.
		 * The CommunicationData is necessary for the SiteProxyPop's to initialization.
		 * @param commConfigXml
		 * @return 
		 */
		protected function createCommunicationData( commConfigXml:XML ):CommunicationData
		{
			// parse xml to define CommunicationData
			var commnData:CommunicationData = new CommunicationData();
			// setup php urls
			commnData.setupPHPDict( commConfigXml );
			// setup host urls
			setupHosts( commnData, commConfigXml );
			trace("CreateConnection Step :: createCommunicationData : set gameHost", commnData.gameHost, "fileHost", commnData.fileHost, "staticHost", commnData.staticHost);
			return commnData;
		}
		
		/**
		 * For override, should be overridden for each platform.
		 * Defines the host values.
		 * @param commnData
		 * @param commConfigXML 
		 */
		protected function setupHosts( commData:CommunicationData, commConfigXML:XML ):void
		{	
			commData.assignHostConfig( commConfigXML );
		}
		
	}
}