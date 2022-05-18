package com.poptropica.shells.shared.steps
{
	import com.poptropica.AppConfig;
	
	import flash.events.Event;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.system.Capabilities;
	
	import engine.managers.FileManager;
	
	import game.data.ads.AdCampaignType;
	import game.data.ads.AdData;
	import game.data.ads.AdvertisingConstants;
	import game.data.comm.PopResponse;
	import game.managers.ads.AdManager;
	import game.managers.ads.AdManagerBrowser;
	import game.managers.interfaces.IAdManager;
	import game.proxy.DataStoreRequest;
	import game.proxy.IDataStore2;
	import game.proxy.PopDataStoreRequest;
	import game.util.PlatformUtils;
	
	public class SetupCampaigns extends ShellStep
	{
		public function SetupCampaigns()
		{
			super();
		}
		
		override protected function build():void
		{
			// determine if showing ads or not
			// default is that ads are on
			if (AppConfig.adsActive)
			{
				shellApi.logWWW("Shell :: " + this + " :: Ads are turned ON");
				
				// define acceptable ad types
				setAdTypes();

				// create add AdManager & initialize
				_adManager = createAdManager();
				_adManager.init(_adTypes);
				
				// get list of campaign names for records requiring campaign.xml (campaigns with cards)
				// need this for mobile and AS2 cards so cards will have correct clickURLs
				getCampaignsWithXML();
			}
			else 
			{
				// if no ads
				shellApi.logWWW("Shell :: " + this + " :: Ads are turned OFF");
				
				built();
			}
		}
		
		/**
		 * set browser-specific ad types
		 * overriden on mobile
		 */
		protected function setAdTypes():void
		{
			// these campaigns occur across all islands
			_adTypes = [AdCampaignType.MAIN_STREET,
						AdCampaignType.AUTOCARD,
						AdCampaignType.VENDOR_CART,
						AdCampaignType.WRAPPER,
						AdCampaignType.NPC_FRIEND,
						AdCampaignType.WEB_PHOTO_BOOTH,
						AdCampaignType.WEB_MINI_GAME,
						AdCampaignType.WEB_BLIMP,
						AdCampaignType.WEB_SCAVENGER_ITEM,
						AdCampaignType.STANDARD_DISPLAYBILLBOARD,
						AdCampaignType.ARCADE_TAKEOVER
						];
		}
		
		/**
		 * Create the AdManager and add to ShellApi.
		 * Should be overridden where platform specific version of Admanager is required (browser and mobile)
		 * @return AdManager
		 */
		protected function createAdManager():AdManager
		{
			return shellApi.addManager(new AdManagerBrowser(), IAdManager) as AdManager;
		}
		
		/**
		 * Get list of campaign names for records requiring campaign.xml
		 */
		protected function getCampaignsWithXML():void
		{
			// if pulling active campaigns from CMS
			if ( determinePullFromCMS() )
			{
				// make AMFPHP call to server to get campaign names for records requiring campaign.xml
				var req:DataStoreRequest = PopDataStoreRequest.WebCampaignsXMLRequest();
				req.requestTimeoutMillis = 2000;
				(shellApi.siteProxy as IDataStore2).call(req, getCampaignsWithXMLCallback);
			}
			else
			{
				// platform-specific setup
				setupCampaigns();
			}
		}
		
		/**
		 * Get campaign.xml files done
		 */
		protected function getCampaignsWithXMLCallback(response:PopResponse = null):void
		{
			_adManager.processCampaignsWithXML(response);
			// platform-specific setup
			setupCampaigns();			
		}
		
		/**
		 * Set up campaigns
		 * overriden on mobile
		 */
		protected function setupCampaigns():void
		{
			shellApi.logWWW("SetupCampaigns::setupCampaigns()");
			// if pulling active campaigns from CMS or mobile
			if ( determinePullFromCMS() )
			{
				shellApi.logWWW("we are pulling from CMS, so no adlocal. done");
				// skip to last step
				// don't need to get list of active campaigns from CMS here (unlike mobile)
				// on browser, we expire cards based on the LSO which lists active campaign card IDs
				doneWithCampaigns();
			}
			// if not pulling from CMS and debugging and not mobile app, then use campaigns from AdLocal
			else if ((AppConfig.debug) && (!PlatformUtils.isMobileOS))
			{
				shellApi.logWWW("not pulling from CMS, so load local");
				loadLocalDataXML();
			}
			else
			{
				shellApi.logWWW("SetupCampaigns : network not available, cannot retrieve active campaigns from CMS.");
				built();
			}
		}
		
		///////////////////////// CHECKS /////////////////////////
		
		/**
		 * Determine if active campaign list should be pulled from CMS
		 * @return Boolean
		 */
		protected function determinePullFromCMS():Boolean
		{
			// if network available or test mode and pulling ads from CMS
			return ( ((shellApi.networkAvailable()) || (Capabilities.playerType == "Desktop")) && (AppConfig.adsFromCMS) );
		}
		
		///////////////////////// UTILITIES /////////////////////////
		
		/**
		 * FOR DEBUG : Load local ad data xml (browser or mobile)
		 */
		protected function loadLocalDataXML():void
		{
			shellApi.logWWW(this," :: DEBUG :: loadLocalDataXML : uses campaigns from local xml");
			// don't use file manager for loading or else it will pull from the server instead of locally
			var ldr:URLLoader = new URLLoader();
			ldr.addEventListener(Event.COMPLETE, gotLocalDataXML);
			var fileManager:FileManager = shellApi.getManager(FileManager) as FileManager;
			shellApi.logWWW("SetupCampaigns::loadLocalDataXML() will load", fileManager.dataPrefix + AdvertisingConstants.AD_LOCAL_FILE);
			ldr.load(new URLRequest(fileManager.dataPrefix + AdvertisingConstants.AD_LOCAL_FILE));
		}

		/**
		 * FOR DEBUG : Handler for local ad data xml when loaded (browser or mobile)
		 * Converts XML into AdData and adds to active campaigns appropriately
		 * @param xml
		 */
		private function gotLocalDataXML(event:Event):void
		{
			var xml:XML = new XML(event.currentTarget.data);
			shellApi.logWWW("SetupCampaigns::gotLocalDataXML()", xml? xml.toXMLString() : "xml is null");
			
			var localAdData:Vector.<AdData> = new Vector.<AdData>();
			if (xml) 
			{
				var children:XMLList = xml.children();
				shellApi.logWWW("xml has", children ? children.length() : "ZERO", "children");
				var fileManager:FileManager = shellApi.fileManager;
				
				// for ads in local xml
				for (var j:int = children.length() - 1; j!=-1; j--)
				{
					shellApi.logWWW("child", j, (children[j] as XML).toXMLString());
					var adData:AdData = new AdData();
					// parse into adData object
					adData.parseLocalXML(children[j] as XML);
					shellApi.logWWW("after parsing XML, adData is", adData.toString());
					// copy video file to file2 property if found
					if (adData.videoFile)
						adData.campaign_file2 = adData.videoFile;
					// copy video file to file2 property if found
					if (adData.campaign_file1)
						adData.campaign_file1 = adData.campaign_file1;
					// force island to be custom island
					adData.island = AdvertisingConstants.AD_ISLAND;
					// check for campaign name suffixes
					var delimiterIndex:int = adData.campaign_name.indexOf(AdvertisingConstants.CAMPAIGN_ALIAS_DELIMITER);
					shellApi.logWWW("check for suffixes, index is", delimiterIndex);
					// if suffix used, then get it
					if (delimiterIndex != -1)
					{
						// get suffix
						var suffix:String = adData.campaign_name.substr(delimiterIndex + 1);
						// if mobile
						if (AppConfig.mobile)
						{
							// if no mobile suffix then add it
							if (suffix.indexOf(AdvertisingConstants.MobileSuffix) == -1)
							{
								suffix += AdvertisingConstants.MobileSuffix;
							}
							// replace web with mobile
							suffix = suffix.replace(AdvertisingConstants.WebSuffix, AdvertisingConstants.MobileSuffix); 
						}
						else
						{
							// if web
							// if no web suffix then add it
							if (suffix.indexOf(AdvertisingConstants.WebSuffix) == -1)
							{
								suffix += AdvertisingConstants.WebSuffix;
							}
							// replace mobile with web
							suffix = suffix.replace(AdvertisingConstants.MobileSuffix, AdvertisingConstants.WebSuffix); 
						}
						adData.suffix = suffix;
						trace("suffix is" + suffix);
						adData.campaign_name = adData.campaign_name.substr(0, delimiterIndex);
						trace("campaign name is " + adData.campaign_name);
					}
					else 
					{
						// if no suffix then use defaults
						//if (AppConfig.mobile)
						//	adData.suffix = AdvertisingConstants.MobileSuffix;
						//else
						//	adData.suffix = AdvertisingConstants.WebSuffix;
						adData.suffix = "";
					}
					
					// determine if campaign type matches platform, if match add to active campaigns 
					var addToList:Boolean = ( PlatformUtils.isMobileOS ) ? adData.isMobileType() : !adData.isMobileType();
					if (addToList)
					{
						shellApi.logWWW("adding", JSON.stringify(adData), "to localAdData");
						localAdData.push(adData);
					}
				}
				shellApi.logWWW(localAdData, "goes off to AdManager");
				// pass array to adManager to be added to campaign lists
				_adManager.updateAdData(localAdData);
				// jump to last step
				doneWithCampaigns();
			} 
			else 
			{
				// if failure
				shellApi.logWWW(this," :: ERROR :: gotLocalDataXML : there was no xml.");
				doneWithCampaigns();
			}
		}
		
		////////////////////////////////// TERMINATION FUNCTIONS //////////////////////////////////
		
		/**
		 * When done processing campaigns, load ad settings
		 * Overriden on mobile which doesn't load ad settings
		 */
		protected function doneWithCampaigns():void
		{
			var fileManager:FileManager = shellApi.getManager(FileManager) as FileManager;
			shellApi.logWWW("SetupCampaigns::doneWithCampaigns() will load settings from", fileManager.dataPrefix + AdvertisingConstants.AD_SETTINGS_FILE);
			fileManager.loadFile(fileManager.dataPrefix + AdvertisingConstants.AD_SETTINGS_FILE, gotAdSettingsXML);
		}
		
		/**
		 * Handler for retrieval of ad settings xml when loaded
		 * @param xmlServer for server xml data
		 * @param xmlStorage for local mobile storage xml data (mobile only
		 */
		protected function gotAdSettingsXML(xmlServer:XML, xmlStorage:XML = null, param:Object = null):void
		{
			//shellApi.logWWW("SetupCampaigns::gotAdSettingsXML() received", xmlServer.toXMLString());
			// pass xml to adManager
			AdManager(shellApi.adManager).gotAdSettingsXML(xmlServer);
			// end of step
			shellApi.logWWW("handed that XML off to AdManager, so we're all built");
			built();
		}
		
		protected var _adTypes:Array;
		protected var _adManager:AdManager;
	}
}