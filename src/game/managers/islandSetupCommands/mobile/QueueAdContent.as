package game.managers.islandSetupCommands.mobile
{
	import com.poptropica.AppConfig;
	
	import engine.ShellApi;
	
	import game.data.ads.AdCampaignType;
	import game.data.ads.AdData;
	import game.data.ads.AdvertisingConstants;
	import game.data.dlc.DLCContentData;
	import game.managers.DLCManager;
	import game.managers.ads.AdManager;
	import game.managers.ads.AdManagerMobile;
	import game.managers.islandSetupCommands.GetAds;
	import game.util.DataUtils;
	import game.utils.AdUtils;
	
	/**
	 * GetAds
	 * 
	 * If ads are active this command will check if any exist on a new island.  If so it will load the required content.
	 * (might want the check and load to happen in separate commands.)
	 */
	
	public class QueueAdContent extends GetAds
	{
		/**
		 * Start command to get ad content for island
		 * @param shellApi
		 * @param nextIsland - island being opened
		 * @param newIsland - flag determining if new, essentailly if the next island is not equal to current island
		 */
		public function QueueAdContent(shellApi:ShellApi, nextIsland:String, newIsland:Boolean)
		{
			super(shellApi, nextIsland, newIsland);
		}
		
		override public function execute():void
		{
			// if ads are active and new island and not Start island
			// TODO :: Want better may to delineate islands (such as Start) that won't have ad content - bard
			if ((AppConfig.adsActive) && (_newIsland) && (_nextIsland != "Start"))
			{
				// set flag determining if headed to ad island (custom island) to display quest interior scene
				// can come from either map or ad building 
				_isCustomAdIsland = ( _nextIsland == AdvertisingConstants.AD_ISLAND );
				
				var adManager:AdManager = _shellApi.adManager as AdManager;
				
				// delete campaigns for current island and next island
				if (_shellApi.island)
				{
					adManager.removeAdDataByIsland(_shellApi.island);
					// don't delete photoBoothIsland data since we just set it in PhotoBoothGroup
					if (_nextIsland != "PhotoBoothIsland")
						adManager.removeAdDataByIsland(_nextIsland);
					
					// if custom island then remember scene, so AdManager knows what scene to return to
					if (_isCustomAdIsland)
						adManager.saveSceneForEntrance();
				}

				// if no network then we can't load anything
				if ((_shellApi.networkAvailable()) || (AppConfig.debug))
				{
					// if custom island, then determine ad content without pulling from CMS
					// We just need to know what zips to download, because the quest has already been determined by entrance ad
					if (_isCustomAdIsland)
					{
						determineAdContent();
					}
					else if (_nextIsland == "PhotoBoothIsland")
					{
						// don't access CMS for photo booth interiors
						determineAdContent();
					}
					else
					{
						// if any other island
						var adTypes:Array;
						
						// if map, then set adTypes to array of mobile map ads and blimp
						if (_nextIsland == "Map")
						{
							adTypes = AdvertisingConstants.MAP_ADS_LIST.slice();
							adTypes.push(AdCampaignType.WEB_BLIMP);
							adTypes.push(AdCampaignType.APP_OF_THE_DAY);
						}
						
						// get campaigns for new island
						// if adTypes is null, then adManager will use default types
						trace("QueueAdContent: pull campaigns from CMS prior to determining ad content for island: " + _nextIsland);
						adManager.getCampaignsForIsland(_nextIsland, adTypes, determineAdContent);
					}
					return;
				}
			}
			completeStep();
		}
		
		/**
		 * Determine what ad zips to load after getting CMS content 
		 */
		private function determineAdContent():void
		{
			trace("QueueAdContent: determine ad content");
			var adManager:AdManagerMobile = _shellApi.adManager as AdManagerMobile;
			
			// init empty ad list
			_ads = [];
			
			// if going to ad quest interior
			if( _isCustomAdIsland )
			{
				// get ad data from door entered
				var ad:AdData = adManager.interiorAd;
				var questName:String;
				// if found, then add quest name to ad list
				if (ad)
				{
					// convert to quest ad, if applicable
					// TODO :: Why can't we specify the quest prior to the this point? - Bard
					questName = AdUtils.convertNameToQuest(ad.campaign_name);
					trace("QueueAdContent: current campaign for custom island: " + ad.campaign_name + " converted to quest: " + questName);
					
				}
				else if(DataUtils.validString(adManager.interiorSuffix))
				{
					var index:int = adManager.interiorSuffix.indexOf("_Interior");
					if(index > 0)
						questName = adManager.interiorSuffix.substr(0,index);
				}
				if(DataUtils.validString(questName))
					_ads.push(questName);
				else
				{
					trace("QueueAdContent: Failure to find any current ad data");
				}
			}
			
			// if going to map
			else if ( _nextIsland == "Map" )
			{
				// check all eight mobile map ad slots
				for each (var slot:String in AdvertisingConstants.MAP_ADS_LIST)
				{
					// if found map ad in CMS data, then add to ad list
					var mapAd:AdData = adManager.getAdData(slot, false, false, "Map");
					if (mapAd)
						_ads.push(mapAd.campaign_name);
				}
			}
			
			// if going to lego island
			// add sponsored islands here
			else if (_nextIsland == "Lego" || _nextIsland == "AmericanGirl")
			{
				// get main street ads
				var mainStreetAd:AdData = adManager.getAdData(AdCampaignType.MAIN_STREET, true, false, _nextIsland);
				// if found ad in CMS data, then add to ad list
				if (mainStreetAd)
					_ads.push(mainStreetAd.campaign_name);
				mainStreetAd = adManager.getAdData(AdCampaignType.MAIN_STREET2, false, false, _nextIsland);
				// if found ad in CMS data, then add to ad list
				if (mainStreetAd)
					_ads.push(mainStreetAd.campaign_name);
				mainStreetAd = adManager.getAdData(AdCampaignType.MAIN_STREET3, false, false, _nextIsland);
				// if found ad in CMS data, then add to ad list
				if (mainStreetAd)
					_ads.push(mainStreetAd.campaign_name);
			}
			
			// if going to photobooth island
			else if (_nextIsland == "PhotoBoothIsland")
			{
				// get photo booth interior
				var photoBoothAd:AdData = adManager.getAdData(AdCampaignType.PHOTO_BOOTH_INTERIOR, true, false, _nextIsland);
				// if found ad in CMS data, then add to ad list with Interior suffix
				if (photoBoothAd)
					_ads.push(photoBoothAd.campaign_name + "Interior");
			}
			
			// if going to standard island
			else
			{
				// check for main street ad
				mainStreetAd = adManager.getAdData(AdCampaignType.MAIN_STREET, false, false, _nextIsland);
				// if found ad in CMS data, then add to ad list
				if (mainStreetAd)
					_ads.push(mainStreetAd.campaign_name);
				
				// check for billboard ad (don't get billboard if home scene)
				// TODO :: Should really list within the island's data what ad slots it has avaialble - bard
				/*
				if (_nextIsland != "Hub")
				{
					var billboard:AdData = adManager.getAdData(AdCampaignType.MOBILE_MINI_BILLBOARD, true, false, _nextIsland);
					// if found ad in CMS data, then add to ad list
					if (billboard)
						_ads.push(billboard.campaign_name);
				}
				*/
				// added second ad spot to hub
				if(_nextIsland == "Hub")
				{
					mainStreetAd = adManager.getAdData(AdCampaignType.MAIN_STREET2, false, false, _nextIsland);
					// if found ad in CMS data, then add to ad list
					if (mainStreetAd)
						_ads.push(mainStreetAd.campaign_name);
				}
				
				// check for mobile photo booth
				var photobooth:AdData = adManager.getAdData(AdCampaignType.WEB_PHOTO_BOOTH, false, false, _nextIsland);
				// if found ad in CMS data, then add to ad list
				if (photobooth)
					_ads.push(photobooth.campaign_name);
				
				// check for mobile autocard
				var autocard:AdData = adManager.getAdData(AdCampaignType.AUTOCARD, false, false, _nextIsland);
				// if found ad in CMS data, then add to ad list
				if (autocard)
					_ads.push(autocard.campaign_name);
				
				// check for minigame (mini-games are off main)
				var miniGame:AdData = adManager.getAdData(AdCampaignType.WEB_MINI_GAME, true, false, _nextIsland);
				if (miniGame)
					_ads.push(miniGame.campaign_name);
				
				// check for blimp takeover
				var blimp:AdData = adManager.getAdData(AdCampaignType.WEB_BLIMP, false, false, _nextIsland);
				if (blimp)
					_ads.push(blimp.campaign_name);
				
				// check for vendor cart
				var vendorCart:AdData = adManager.getAdData(AdCampaignType.VENDOR_CART, false, false, _nextIsland);
				if (vendorCart)
					_ads.push(vendorCart.campaign_name);
			}
				
			// if ad zips to download, then queue ad zips
			if (_ads.length != 0)
			{
				queueAdContent();
			}
			else 
			{
				// if no ad zips to download, then skip queueing
				trace("QueueAdContent: no ad content to queue");
			}
			this.completeStep();
		}
		
		/**
		 * Add advertising DLC to DLCManager's queue 
		 */
		private function queueAdContent():void
		{
			trace("QueueAdContent: ad content to queue: " + _ads);
			var dlcManager:DLCManager = _shellApi.dlcManager;
			
			// for each campaign
			for each (var campaignName:String in _ads)
			{
				// get dlc content data for ad, if not found then skip (should have data if updateCheckSum was already called for the campaign)
				var dlcData:DLCContentData = dlcManager.getDLCContentData(campaignName);
				if (dlcData)
				{
					_shellApi.dlcManager.queueContentByData(dlcData);	// add to queue
				}
				else
				{
					trace(this," :: queueAdContent: no dlcData for campaign " + campaignName);
				}
			}
		}
		
		/**
		 * Last step in sequence 
		 * 
		 */
		private function completeStep():void
		{
			// the 'custom' island has no content of its own, it is merely a shell for ad content
			// since there is not actual content we can skip the next command which is QueueIslandContent
			if ( _isCustomAdIsland )
			{
				super.complete( 2 );
			}
			else
			{
				super.complete();
			}
		}
		
		private var _ads:Array;
		private var _isCustomAdIsland:Boolean = false;
	}
}