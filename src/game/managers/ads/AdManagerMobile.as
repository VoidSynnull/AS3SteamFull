package game.managers.ads
{
	import com.poptropica.AppConfig;
	
	import flash.system.Capabilities;
	
	import ash.core.Entity;
	
	import engine.group.Group;
	
	import game.components.hit.Door;
	import game.data.ads.AdCampaignType;
	import game.data.ads.AdData;
	import game.data.ads.AdvertisingConstants;
	import game.data.dlc.DLCContentData;
	import game.data.dlc.PackagedFileState;
	import game.data.scene.DoorData;
	import game.managers.DLCManager;
	import game.managers.interfaces.IDLCValidator;
	import game.proxy.browser.AdProxyUtils;
	import game.util.ClassUtils;
	import game.utils.AdUtils;
	
	public class AdManagerMobile extends AdManager implements IDLCValidator
	{
		// boolean for pausing game and showing ad versus showing ad over loading screen
		// showing the ad over the loading screen sometimes causes memory issues if the ad is complex
		private var pauseGame:Boolean = true;
		
		// ad manager is created only if ads are active
		public function AdManagerMobile()
		{
			// determine if mobile
			var os:String = Capabilities.os;
		}
				
		// OVERRIDEN FUNCTIONS/////////////////////////////////////////////////////////////////////
		
		/**
		 * Initialize ad manager for mobile
		 * @param adTypes ad types that are suppored on mobile
		 */
		override public function init(adTypes:Array):void
		{
			super.init(adTypes);
			
			// attach listener for whenever a current scene is faded out
			
			// set ad types (these differ between browser and mobile)
			_mainStreetType = AdCampaignType.MAIN_STREET;
			//_billboardType = AdCampaignType.BILLBOARD;
			_autocardType = AdCampaignType.AUTOCARD;
			_npcFriendType = AdCampaignType.NPC_FRIEND;
			_vendorCartType = AdCampaignType.VENDOR_CART;
			_carouselType = AdCampaignType.WEB_CAROUSEL;
			_photoBoothType = AdCampaignType.WEB_PHOTO_BOOTH;
			_miniGameType = AdCampaignType.WEB_MINI_GAME;
			_blimpType = AdCampaignType.WEB_BLIMP;
			_theaterPosterType = AdCampaignType.WEB_THEATER_POSTER;
			_scavengerItemType = AdCampaignType.WEB_SCAVENGER_ITEM;
			_minibillboardType = AdCampaignType.STANDARD_DISPLAYBILLBOARD;
			_homePopupType = AdCampaignType.WEB_HOME_POPUP;
			adTypes.push(AdCampaignType.ARCADE_TAKEOVER);
		}
		
		/**	
		 * Triggered on every scene load 
		 * Handler for SceneManager's sceneLoaded signal
		 * @param scene
		 */
		override protected function handleSceneLoaded(scene:Group):void
		{
			super.handleSceneLoaded(scene);
			
			// send any cached tracking pixels if network available
			if (super.shellApi.networkAvailable())
				AdProxyUtils.sendCachedTrackingPixels();
		}
				
		/**
		 * When door reached - figure out scene on other side of connecting doors 
		 * @param charEntity
		 * @param doorEntity
		 * @param destination
		 */
		override public function doorReached(charEntity:Entity, doorEntity:Entity):void
		{
			// get door data
			var doorData:DoorData = doorEntity.get(Door).data;
			super.doorReached(charEntity, doorEntity);
		}
		
		/**
		 * Update campaigns content with new campaign data
		 * Checks campaign data to determine if ad content requires installation/reinstallation
		 * @param dataArray array of AdData objects
		 */
		override public function updateAdData(dataArray:Vector.<AdData>):void
		{
			// prefix to ad zip directory
			var networkPrefix:String = "https://" + shellApi.siteProxy.fileHost + AdvertisingConstants.ZIP_DIRECTORY;
			var dlcManager:DLCManager = shellApi.dlcManager;
			
			var adData:AdData; 
			var dlcData:DLCContentData;
			var checkSumArray:Array;
			var checkSum:String
			var i:int = 0;
			//var hasBillboard:Boolean = false;
			
			// for each ad in array
			for (i; i < dataArray.length; i++) 
			{
				// get ad data
				adData = dataArray[i];
				
				//if (adData.campaign_type == AdCampaignType.BILLBOARD)
				//	hasBillboard = true;
				
				// skip if carousel billboard since no ad zips are used
				if (adData.campaign_type.indexOf(AdCampaignType.WEB_CAROUSEL) != -1)
				{
					makeAdDataCampaignsActive(adData);
					continue;
				}
				
				/**
				 * In case of mobile ad content, the checkSum is passed along with the campiagn data via CMS
				 * If there is a Quest associated wth the campaign it's checkSum is also included in the comma-delimited string
				 * Ad team is responsible for manually updating checkSum in CMS if a change has been made to the contents
				 * The file1 field in CMS is used to hold checksums for mobile
				 * The field should look like "checksum1" or "checksum1,questchecksum1" if the campaign has an associated quest
				 * WARNING :: Multiple campaigns can point to the same Quest, need to make sure Quest checkSums align across campaigns in CMS
				 */
				
				// get checksum value for campaign
				// default checksum if none is found
				checkSum = "checksum0";
				// if file1 field is not empty
				if( adData.campaign_file1 )
				{
					// get value and split if comma-delimited list
					checkSumArray = adData.campaign_file1.split(",");
					// if not empty array, then get checksum for campaign
					if( checkSumArray.length > 0 )
					{
						checkSum = checkSumArray[0];
					}
				}
				else
				{
					// if file1 field is empty, then set array to null
					checkSumArray = null;
				}
				trace("AdManagerMobile :: updateAdData :: for campaign: " + adData.campaign_name + ", checksum: " + checkSum );
				
				/**
				 * TODO :: This assumes that all ad content only has a single content zip file associated with it.
				 * This may not always be the case, if that changes this logic will have to change as well to account for multiple files
				 */
				
				// if not ignoring dlc
				if (!AppConfig.ignoreDLC)
				{
					// create new DLCContentData, if already created will not recreate
					dlcData = dlcManager.createDLCData(adData.campaign_name, [adData.campaign_name], PackagedFileState.REMOTE_COMPRESSED, DLCManager.TYPE_SECONDARY_CONTENT, networkPrefix, this);
					dlcData.validatorDelegate = this;	// NOTE :: Need to reset this as it doesn't get stored along with global data
					// create/update DLCFileData checksum value
					dlcManager.updateCheckSum(adData.campaign_name, checkSum, dlcData);
					
					// determine if campaign has a Quest associated with it, if so update Quest content as well
					var questName:String = AdUtils.convertNameToQuest(adData.campaign_name);
					if (adData.campaign_name != questName)
					{
						// get checkSum value for Quest associated with campaign
						// default checksum if none is found
						checkSum = "checksum0";
						// if array and array has 2 or more values, then get checksum
						if ((checkSumArray) && (checkSumArray.length >= 2))
						{
							checkSum = checkSumArray[1];
						}
						trace("AdManagerMobile :: updateAdData : for quest: " + questName + ", checksum: " + checkSum);
						
						/**
						 * NOTE :: If loading into an ad Quest, then the content should be considered 'island' content
						 * This is because if the 'island' content fails to load, the IslandManager will abort its attempt to access the island
						 * If content is only additive (billboard, Vendor Carts, etc) then we can still proceed with island loading
						 * The difference is that we use primary content for quests versus secondary content for other ad types
						 */
						// create new DLCContentData, if already created will not recreate
						dlcData = dlcManager.createDLCData(questName, [questName], PackagedFileState.REMOTE_COMPRESSED, DLCManager.TYPE_PRIMARY_CONTENT, networkPrefix, this);
						dlcData.validatorDelegate = this;	// NOTE :: Need to reset this as it doesn't get stored along woth global data
						// create/update DLCFileData checksum value
						dlcManager.updateCheckSum(questName, checkSum, dlcData)
					}
					
					// if content was found to be invalid, don't add to list of active campaigns
					if ( !dlcManager.blockInvalidContent(adData.campaign_name) )
					{
						_cmsCampaigns.push(adData);
					}
					else
					{
						trace(this," :: updateAdData : block invalid campaign: " + adData.campaign_name);
					}
				}
				else
				{
					// if ignoring DLC then make campaign active
					makeAdDataCampaignsActive(adData);
				}
			}
			trace(this," :: updateAdData : adding " + dataArray.length + " more campaigns. Total:" + _cmsCampaigns.length);
		}
		
		// MOBILE MAP AD FUNCTIONS ///////////////////////////////////////////////////////////////
		
		/**
		 * checks for any active mobile map ads and return array of campaign names (called from Map)
		 * @param init
		 * @return array
		 */
		public function getMobileMapAds():Array
		{
			var count:int = 0;
			var arr:Array = [];
			// for all eight mobile map ad types ad types
			for each (var type:String in AdvertisingConstants.MAP_ADS_LIST)
			{
				count++;
				// get ad data for map ad on current scene (Map in this case)
				var mapAd:AdData = getAdData(type, false);
				// if found, then add to array
				if (mapAd)
				{
					arr.push(mapAd.campaign_name);
					trace("AdManagerMobile :: MapAd: slot: " + count + ", campaign name: " + mapAd.campaign_name);
				}
			}
			return arr;
		}
		
		/**
		 * Load quest interior (called from Map)
		 * QuestInterior class will figure out what campaign is active
		 */
		public function loadQuestInterior():void
		{
			// get quest interior class and load that scene
			var questInteriorClass:Class = ClassUtils.getClassByName('game.scenes.custom.questInterior.QuestInterior');
			shellApi.islandManager.loadScene(questInteriorClass);
		}
		
		// UTIILITY FUNCTIONS //////////////////////////////////////////////////////////
		
		/**
		 * Validate ad content zip
		 * Called when ad zip is newly downloaded or validation flag has been expressly reset
		 * Ad won't display if validation fails
		 * @param dlcData
		 * @param onComplete
		 */
		public function validateContent( dlcData:DLCContentData, onComplete:Function ):void
		{
			// if data exists, then validate ad zip
			if( dlcData )
			{
				trace("AdManager: validating ad zip for " + dlcData.contentId);
				new AdZipValidator(shellApi, dlcData, onComplete);
			}
			else
			{
				// if no data, then trigger callback if exists
				trace("Error :: AdManager: validateAdZip : dlcData was not sent.");
				if ( onComplete != null ) { onComplete(null); }
			}
		}
		
		/**
		 * Delete campaign adData object based on campaign name, search on all islands
		 * Called when ad zip validation fails
		 * Prevents ad from displaying
		 * @param campaignName
		 */
		public function deleteCampaign( campaignName:String):void
		{
			trace("AdManager: deleting campaign " + campaignName);
			// for each (var ad:AdData in _cmsCampaigns)
			for (var i:int = _cmsCampaigns.length-1; i!= -1; i--)
			{
				var ad:AdData = _cmsCampaigns[i];
				// if ad has matching campaign name, then delete
				if (ad.campaign_name == campaignName)
					_cmsCampaigns.splice(i,1);
			}
		}
	}
}
