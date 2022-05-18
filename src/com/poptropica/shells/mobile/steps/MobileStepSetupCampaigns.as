package com.poptropica.shells.mobile.steps
{
	import com.poptropica.AppConfig;
	import com.poptropica.shells.shared.steps.SetupCampaigns;
	
	import flash.filesystem.File;
	import flash.net.URLVariables;
	import flash.utils.Dictionary;
	
	import engine.managers.FileManager;
	import engine.util.Command;
	
	import game.data.ads.AdCampaignType;
	import game.data.ads.AdvertisingConstants;
	import game.data.character.LookConverter;
	import game.data.character.LookData;
	import game.data.character.PlayerLook;
	import game.data.comm.PopResponse;
	import game.data.profile.ProfileData;
	import game.managers.DLCManager;
	import game.managers.ProfileManager;
	import game.managers.ads.AdManager;
	import game.managers.ads.AdManagerMobile;
	import game.managers.interfaces.IAdManager;
	import game.proxy.DataStoreRequest;
	import game.proxy.IDataStore2;
	import game.proxy.PopDataStoreRequest;
	import game.scene.template.ui.CardGroup;
	import game.utils.AdUtils;
	import game.util.PlatformUtils;
	
	/**
	 * This class sets the mobile ad types, the mobile ad manager, and deletes any expired mobile campaigns with their assets 
	 * @author uhockri
	 * 
	 */
	public class MobileStepSetupCampaigns extends SetupCampaigns
	{
		public function MobileStepSetupCampaigns()
		{
			super();
		}
		
		/**
		 * Set mobile-specific ad types
		 */
		override protected function setAdTypes():void
		{
			// this is used when pulling ads for all islands but does not include map ads which are handled separately when loading map
			// same as web except for wrapper (see SetupCampaigns)
			_adTypes = [AdCampaignType.MAIN_STREET,
						AdCampaignType.WEB_PHOTO_BOOTH,
						AdCampaignType.AUTOCARD,
						AdCampaignType.WEB_BLIMP,
						AdCampaignType.WEB_MINI_GAME,
						AdCampaignType.WEB_SCAVENGER_ITEM,
						AdCampaignType.VENDOR_CART,
						AdCampaignType.STANDARD_DISPLAYBILLBOARD,
						AdCampaignType.WEB_HOME_POPUP,
						AdCampaignType.ARCADE_TAKEOVER
						];
			// add mobile map ads to _adTypes to get full list of ad types
			_allAdTypes = _adTypes.concat([AdCampaignType.WEB_MAP_AD1, 
											AdCampaignType.WEB_MAP_AD2,
											AdCampaignType.WEB_MAP_AD3,
											AdCampaignType.WEB_MAP_AD4,
											AdCampaignType.WEB_MAP_AD5,
											AdCampaignType.WEB_MAP_AD6,
											AdCampaignType.WEB_MAP_AD7,
											AdCampaignType.WEB_MAP_AD8
											]);
		}
		
		/**
		 * Create ad manager for mobile
		 * @return AdManagerMobile
		 */
		override protected function createAdManager():AdManager
		{
			// use AdManagerMobile even when ignoring DLC in order to test mobile ads locally
			return shellApi.addManager(new AdManagerMobile(), IAdManager) as AdManagerMobile;
		}
		
		/**
		 * Get list of campaign names for records requiring campaign.xml
		 */
		override protected function getCampaignsWithXML():void
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
		 * Set up campaigns for mobile
		 * Get list of active campaigns from CMS or pull campaigns from local xml
		 */
		override protected function setupCampaigns():void
		{
			// save file manager since this is used in a number of functions
			_fileManager = FileManager(super.shellApi.getManager(FileManager));
			
			// Force all ad zips to revalidate once per session
			// This also insures that campaign.xml files for campaigns get processed and added to active campaigns
			// This also re-validates invalid ad zips once every session in case the user updates to a later build that has supported classes
			// This does not force a reload of an ad zip unless the checksum has changed in the CMS
			if( shellApi.dlcManager )
			{
				shellApi.dlcManager.forceValidation();
			}
			
			// if able to pull from CMS
			if ( determinePullFromCMS() )
			{
				// pull list of active campaigns for all mobile ad types
				var req:DataStoreRequest = PopDataStoreRequest.activeCampaignsRequest(_allAdTypes);
				req.requestTimeoutMillis = 5000;

				// 2/11/15 _RAM modified return values for request ID: -1 indicates no call was made, 0 or greater is the index into the call array
				// we are passing only those mobile ad types that might have cards: MMQs, MainStreet Ads, Billboards
				var requestId:int = (shellApi.siteProxy as IDataStore2).call(req, gotActiveCMSCampaigns);
				
				// if failure
				if (requestId == -1)
				{
					trace(_traceClassName + "failure to create call to get active campaigns.");
					built();
				}
			}
			// if not pulling from CMS and debugging and not mobile app, then use campaigns from AdLocal
			else if ((AppConfig.debug) && (!PlatformUtils.isMobileOS))
			{
				loadLocalDataXML();
			}
			else
			{
				// if no network and not debugging then skip out
				trace(_traceClassName + "network not available, cannot retrieve active campaigns from CMS.");
				built();
			}
		}
		
		/**
		 * Got list of active campaigns from the CMS
		 */
		private function gotActiveCMSCampaigns(response:PopResponse):void
		{
			// if failure
			if (!response.succeeded)
			{
				trace(_traceClassName + "failure to receive active campaigns from CMS, response: " + response.error);
				built();
			}
			else
			{
				// if success
				// list of active campaigns from CMS
				_activeCMSCampaigns = [];
				// list of active campaigns found in all profiles (not all active campaigns will be found in the profiles)
				_activeProfileCampaigns = [];
				// expired campaigns in profile
				_expiredProfileCampaigns = [];
				// list of active (non-expired) file paths found in all profiles
				_activeFilePathList = [];
				// manifest urls whose contents need to be deleted
				_manifestsToDelete = [];
				
				// convert response data to list of campaigns
				var data:String = String(response.data);
				// if data is not empty
				if (data != "")
				{
					// form of data: campaigns=GalacticHotDogsMMSQ&campaigns=GalacticHotDogsVideoBillboard
					_activeCMSCampaigns = campaignURLToArray(data);
					
					// remove any aliases drom end of the campaign names
					for (var i:int = _activeCMSCampaigns.length-1; i != -1; i--)
					{
						var campaignName:String = _activeCMSCampaigns[i];
						var index:int = campaignName.indexOf("|");
						if (index != -1)
						{
							campaignName = campaignName.substr(0,index);
							_activeCMSCampaigns[i] = campaignName;
						}
					}
			
					// ad quest campaigns to list based on campaign names
					addLinkedQuestCampaigns();
				}
				trace(_traceClassName + "got active campaigns: " + _activeCMSCampaigns);
				
				// get expired campaigns, if any
				// compare the active campaigns to campaigns stored in the profile
				getExpiredCampaigns();
				// now check if any expired campaigns
				checkExpiredCampaigns();
			}
		}
		
		/**
		 * Convert string of campaigns in URL format into Array of campaigns
		 * @param campaignsString - campaign data in URL format [form: campaigns=GalacticHotDogsMMSQ&campaigns=GalacticHotDogsVideoBillboard]
		 * @return - Array of campaigns derived from campaignsString
		 */
		private function campaignURLToArray(campaignsString:String):Array
		{
			var campaigns:Array = [];
			
			// if multiple campaigns
			if (campaignsString.indexOf('&') != -1)
			{
				// convert to URLVariables and extract array
				var vars:URLVariables = new URLVariables(campaignsString);
				if (vars.campaigns is Array)
				{
					campaigns = vars.campaigns;
				}
			}
			else
			{
				// if string has the form campaigns=baz
				// split the string
				var pairs:Array = campaignsString.split('=');
				if ((pairs[0] == "campaigns") && (pairs.length > 1))
				{
					campaigns = [pairs[1]];
				}
			}
			return campaigns;
		}
		
		/**
		 * Check active campaigns for linkage to a corresponding quest
		 * If quest linkage is applicable, add corresponding quest to active campaigns as well
		 */
		private function addLinkedQuestCampaigns():void
		{
			// if any campaigns
			if (_activeCMSCampaigns.length != 0)
			{
				// for each campaign in list
				for (var k:int = _activeCMSCampaigns.length - 1; k!=-1; k--)
				{
					// get campaign name
					var campaignName:String = _activeCMSCampaigns[k];
					// get possible quest name
					var questName:String = AdUtils.convertNameToQuest(campaignName);
					// if quest name is not campaign name, then add to list if not already there
					if (questName != campaignName)
					{
						if (_activeCMSCampaigns.indexOf(questName) == -1)
							_activeCMSCampaigns.push(questName);
					}
				}
			}
		}
		
		////////////////////////////////// EXPIRED CAMPAIGN MANAGEMENT //////////////////////////////////
		
		/**
		 * Determine expired campaigns 
		 * We compare the active campaigns to campaigns stored in the profile
		 * Any campaign that is no longer active will be deleted from profile and local storage
		 */
		private function getExpiredCampaigns():void
		{
			var profileManager:ProfileManager = super.shellApi.profileManager;
			var campaignName:String;
			var questName:String;
			
			// iterate through profiles
			for each (var profile:ProfileData in profileManager.profiles)
			{
				var profileName:String = profile.avatarFirstName + " " + profile.avatarLastName;
				trace(_traceClassName + "campaigns in profile: " + profileName + ": " + profile.campaigns);
				
				// check each campaign name in profile
				for (var i:int = profile.campaigns.length - 1; i!=-1; i--)
				{
					// get campaign name
					campaignName = profile.campaigns[i];
					
					// if in list of active CMS cmapigns
					if (_activeCMSCampaigns.indexOf(campaignName) != -1)
					{
						// add to list of active profile campaigns if not already there
						if (_activeProfileCampaigns.indexOf(campaignName) == -1)
							_activeProfileCampaigns.push(campaignName);
					}
					else 
					{
						// if not in list then add to expired campaigns
						// if not in expired campaign list, then add it
						if (_expiredProfileCampaigns.indexOf(campaignName) == -1)
						{
							_expiredProfileCampaigns.push(campaignName);
							// create possible quest name
							questName = AdUtils.convertNameToQuest(campaignName);							
							// if quest name is not campaign name, then add it if not already there
							if (questName != campaignName)
							{
								if (_expiredProfileCampaigns.indexOf(questName) == -1)
									_expiredProfileCampaigns.push(questName);
							}
						}
					}
				}
			}
			
			var saveProfile:Boolean = false;
			// check each profile again and delete any expired campaigns from profile
			// at this point we have a completed list of expired campaigns along with their quests
			for each (profile in profileManager.profiles)
			{
				profileName = profile.avatarFirstName + " " + profile.avatarLastName;
				for (i = profile.campaigns.length - 1; i!=-1; i--)
				{
					// get campaign name
					campaignName = profile.campaigns[i];
					// if expired campaign list has campaign name
					if (_expiredProfileCampaigns.indexOf(campaignName) != -1)
					{
						// delete from profile
						profile.campaigns.splice(i,1);
						saveProfile = true;
					}
				}
				trace(_traceClassName + "updated campaigns in profile: " + profileName + ": " + profile.campaigns);
			}
			
			// save profiles if profiles have been edited
			if (saveProfile)
				shellApi.profileManager.save();
			
			trace(_traceClassName + "active profile campaigns: " + _activeProfileCampaigns);
			trace(_traceClassName + "expired profile campaigns to delete: " + _expiredProfileCampaigns);
		}
		
		/**
		 * Check for expired campaigns
		 */
		private function checkExpiredCampaigns():void
		{
			// if no expired campaigns found then continue
			if(_expiredProfileCampaigns.length == 0)
			{
				doneRemoveExpired();
			}
			else 
			{
				// if expired campaigns
				// get expired campaign manifests list
				getExpiredManifests();
				
				// if no campaigns need to be deleted, then continue
				if(_manifestsToDelete.length == 0)
				{
					trace(_traceClassName + "no campaigns to remove from local storage");
					doneRemoveExpired();
				}
				else 
				{
					// if files to delete, then get active manifests and load them
					// need list of active files before we can delete any expired files
					getActiveManifests();
				}
			}
		}
		
		/**
		 * Get list of expired manifests whose files need to be deleted
		 * @param expiredCampaigns - array of expired campaigns : list of campaign IDs such as ["GalacticeHotDogsMMSQ", "RealmsMobileBillboard"]
		 * @return - returns true if campaigns found that require removal 
		 */
		private function getExpiredManifests():void
		{
			var dlcManager:DLCManager = super.shellApi.dlcManager;
			if( dlcManager != null )
			{
				// remove DLC content references, DLC is stored globally across all profiles
				// TODO :: Should try to delete actual assets as well, is a TODO in DLCManager - bard
				// Note that assets get deleted in this class, not in the DLCManager
				super.shellApi.dlcManager.removeDLCFromGlobalProfile(_expiredProfileCampaigns);
				
				// iterate through list of expired campaigns
				for (var i:int = 0; i < _expiredProfileCampaigns.length; i++) 
				{
					// get campaign name and trim off any alias suffix
					var expiredCampaignName:String = _expiredProfileCampaigns[i];
										
					// get full path to ad manifest
					var manifestPath:String = getManifestPath(expiredCampaignName);
					
					// see if manifest is in local storage
					if (_fileManager.verifyFileLocation(manifestPath, true) == null)
					{
						trace(_traceClassName + "getExpiredManifests: manifest not found to delete: " + manifestPath);
					}
					else
					{
						// if manifest found
						// add campaign name to array for later loading (first need to load active campaign manifests)
						_manifestsToDelete.push(expiredCampaignName);
					}
				}
			}
		}
		
		/**
		 * Get list of active manifests for campaigns in profile (if any) and load them
		 */
		private function getActiveManifests():void
		{
			// iterate through list of active profile campaigns
			for (var i:int = 0; i < _activeProfileCampaigns.length; i++) 
			{
				// get campaign name and trim off any alias suffix
				var activeCampaignName:String = _activeProfileCampaigns[i];
								
				// get full path to ad manifest
				var manifestPath:String = getManifestPath(activeCampaignName);
				
				// see if manifest is in local storage
				if (_fileManager.verifyFileLocation(manifestPath, true) == null)
				{
					trace(_traceClassName + "getActiveManifests: manifest not found to delete: " + manifestPath);
				}
				else
				{
					// if manifest found
					// load active manifest now
					shellApi.loadFile(manifestPath, Command.create(onActiveManifestLoaded, activeCampaignName));
				}
			}
		}

		/**
		 * When active manifest loaded
		 * @param manifestXML xml from loaded manifest
		 * @param campaignName name of campaign
		 */
		private function onActiveManifestLoaded( manifestXML:XML, campaignName:String):void
		{
			// if xml is null, then error
			if (manifestXML == null)
			{
				trace(_traceClassName + "onActiveManifestLoaded: can't find manifest for " + campaignName);
			}
			else
			{
				// convert manifest into array and exclude current array of file paths to prevent duplicates
				var fileList:Array = AdUtils.getManifestList(manifestXML, true, _activeFilePathList);
				// now add to master list
				_activeFilePathList = _activeFilePathList.concat(fileList);
			}
			// increment ad counter
			_activeAdCounter++;
			// when counter equals total, then load all the expired manifests
			if(_activeAdCounter == _activeProfileCampaigns.length)
			{
				loadExpiredManifests();
			}
		}
		
		/**
		 * Load expired manifests (now that we have the active manifests loaded) 
		 */
		private function loadExpiredManifests():void
		{
			// iterate through list of active profile campaigns
			for (var i:int = 0; i < _manifestsToDelete.length; i++) 
			{
				var expiredCampaignName:String = _manifestsToDelete[i];
				// get full path to manifest
				var manifestPath:String = getManifestPath(expiredCampaignName);
				// load expired manifest
				shellApi.loadFile(manifestPath, Command.create(onExpiredManifestLoaded, expiredCampaignName));
			}
		}

		/**
		 * When expired manifest loaded
		 * @param manifestXML xml from loaded manifest
		 * @param campaignName name of campaign
		 */
		private function onExpiredManifestLoaded( manifestXML:XML, campaignName:String):void
		{
			// if xml is null, then error
			if (manifestXML == null)
			{
				trace(_traceClassName + "onExpiredManifestLoaded: can't find manifest for " + campaignName);
			}
			else
			{
				trace(_traceClassName + "onExpiredManifestLoaded: got manifest for " + campaignName + ". Starting file deletion.");
				
				// convert manifest into array that contains file paths that are not in active file list
				var list:Array = AdUtils.getManifestList(manifestXML, true, _activeFilePathList);
				// list of card IDs
				var expiredCards:Array = getManifestCards(list);
				// list of avatar parts
				var expiredParts:Dictionary = getManifestAvatarParts(list);
				// list of abilities
				var expiredAbilities:Array = getManifestAbilities(list);
				
				// for each profile
				for each (var profile:ProfileData in shellApi.profileManager.profiles)
				{
					var profileName:String = profile.avatarFirstName + " " + profile.avatarLastName;
					// clear profile of expired cards
					removeExpiredCards(profile, profileName, expiredCards);
					// clear profile of expired avatar parts
					removeExpiredAvatarParts(profile, profileName, expiredParts);
					// clear profile of expired abilities
					removeExpiredAbilities(profile, profileName, expiredAbilities);
				}
				
				// now delete files
				shellApi.deleteFiles(list);
				
				// create list of campaign directories to be deleted
				var directories:Array = [];
				for each (var url:String in list)
				{
					var directory:String;
					var arr:Array = url.split("/");
					if (url.indexOf("scenes/limited") != -1)
						directory = arr[0] + "/scenes/limited/" + arr[3];
					else if (url.indexOf("assets/limited") != -1)
						directory = "assets/limited/" + arr[2];
					else if (url.indexOf("data/limited") != -1)
						directory = "data/limited/" + arr[2];
					else
						directory = null;
					
					// if campaign directory and not already in list, then add
					if ((directory) && (directories.indexOf(directory) == -1))
					{
						directories.push(directory);
					}
				}
				
				// now delete directories
				for each (directory in directories)
				{
					trace(_traceClassName + "deleting directory: " + directory);
					var dirFile:File = File.applicationStorageDirectory.resolvePath(directory);
					try
					{
						dirFile.deleteDirectory(true);
					}
					catch(error:Error)
					{
						trace(_traceClassName + "delete directory failure: " + directory + " : " + error.message);
					}
				}
			}
			
			// increment ad counter
			_deleteAdCounter++;
			// when counter equals total
			if(_deleteAdCounter == _manifestsToDelete.length)
			{
				// save profile
				shellApi.profileManager.save();
				// jump to final step
				doneRemoveExpired();
			}
		}
		
		/**
		 * Get list of card item ids from array of expired files
		 * @param expiredFiles array of expired files
		 * @return array of card ids
		 */
		private function getManifestCards(expiredFiles:Array):Array
		{
			var cardList:Array = [];
			
			// for each file path in list of expired files
			for each (var path:String in expiredFiles)
			{
				// if limited cards xml path
				if (path.indexOf("data/items/limited/") == 0)
				{
					// get card ID
					var start:int = path.lastIndexOf("item") + 4;
					var ext:int = path.indexOf(".xml");
					var cardID:String = path.substring(start, ext);
					
					// add to list
					cardList.push(cardID);
				}
			}
			trace(_traceClassName + "cards flagged for deletion: " + cardList);
			return cardList;
		}
		
		/**
		 * Gets avatar parts from array of expired files
		 * @param expiredFiles array of expired files
		 * @return dictionary of Arrays of avatar part ids from campaign manifest.
		 * Dictionary keys are avatar part types.
		 */
		private function getManifestAvatarParts(expiredFiles:Array):Dictionary
		{
			var parts:Dictionary = new Dictionary();
			
			// for each file path in list of expired files
			for each (var path:String in expiredFiles)
			{
				// if avatar part (xml)
				if (path.indexOf("data/entity/character/parts/") == 0)
				{
					// get part type
					var start:int = path.indexOf("parts/") + 6;
					var end:int = path.indexOf("/", start);
					var type:String = path.substring(start, end);
					
					// get part ID
					var ext:int = path.indexOf(".xml");
					var part:String = path.substring(end + 1, ext);
					
					// add part to dictionary as array using type as key
					if (parts[type] == null)
						parts[type] = [part];
					else
						parts[type].push(part);
					trace(_traceClassName + "part flagged for deletion: " + type + " " + part);
				}
			}
			return parts;
		}
		
		/**
		 * Get list of abilities from array of expired files
		 * @param expiredFiles array of expired files
		 * @return array of abilities
		 */
		private function getManifestAbilities(expiredFiles:Array):Array
		{
			var abilityList:Array = [];
			
			// for each file path in list of expired files
			for each (var path:String in expiredFiles)
			{
				// if ability path structure for ads
				if (path.indexOf("data/entity/character/abilities/limited/") == 0)
				{
					// get ability ID
					var start:int = path.indexOf("limited/") + 8;
					var ext:int = path.indexOf(".xml");
					var abilityID:String = path.substring(start, ext);

					// add to list
					abilityList.push(abilityID);
				}
			}
			trace(_traceClassName + "abilities flagged for deletion: " + abilityList);
			return abilityList;
		}
		
		/**
		 * Clear profile of expired cards
		 * @param profile data for one user profile
		 * @param expiredCards array of expired card ids
		 */
		private function removeExpiredCards(profile:ProfileData, profileName:String, expiredCards:Array):void
		{
			// get campaign cards
			var campaignCards:Array = profile.items[CardGroup.CUSTOM];
			// if cards
			if (campaignCards)
			{
				// for each card
				for (var i:int = campaignCards.length-1; i!= -1; i--)
				{
					var card:String = campaignCards[i];
					// if card is listed in expired cards array, then delete
					if (expiredCards.indexOf(card) != -1)
					{
						trace(_traceClassName + "removed expired card from profile: " + profileName + ": " + card);
						campaignCards.splice(i,1);
					}
				}
			}
		}
		
		// TODO :: Need to go through closet looks as well - bard
		/**
		 * Removes expired parts from player's profile look. 
		 * @param profile data for one user profile
		 * @param expiredParts - Dictionary of Arrays, using part type (hair, facial, tec.) as key, Arrays should contain expired part values (party_hat, moustache, etc.) 
		 */
		private function removeExpiredAvatarParts(profile:ProfileData, profileName:String, expiredParts:Dictionary):void
		{
			// create look converter if not yet done
			if (_lookConverter == null )
				_lookConverter = new LookConverter();
			
			// get look for profile (not all profiles have look)
			if (profile.look)
			{
				var look:LookData = _lookConverter.lookDataFromPlayerLook( profile.look );
				// for each key (part) in expired parts dictionary
				for (var key:String in expiredParts)
				{
					// get parts array
					var parts:Array = expiredParts[key] as Array;
					// for each part
					for (var i:int = 0; i < parts.length; i++) 
					{
						// remove part
						if (look.removeLookAspect(key, parts[i], true) )
						{
							trace(_traceClassName + "removed expired part from profile: " + profileName + ": " + key + " id: " + parts[i]);
							// go to the next key
							break;
						}
					}
				}
				// set revised look with removed expired parts
				_lookConverter.playerLookFromLookData( look, profile.look );
			}
			
			// remove expired avatar parts from closet looks
			// for each closet look
			if (profile.closetLooks)
			{
				for each (var closetLook:PlayerLook in profile.closetLooks)
				{
					// get look for closet
					look = _lookConverter.lookDataFromPlayerLook( closetLook );
					// for each key (part) in expired parts dictionary
					for (key in expiredParts)
					{
						// get parts array
						parts = expiredParts[key] as Array;
						// for each part
						for (i = 0; i < parts.length; i++)
						{
							// remove part
							if (look.removeLookAspect(key, parts[i], true))
							{
								trace(_traceClassName + "removed expired closet part from profile: " + profileName + ": " + key + " id: " + parts[i]);
								// go to the next key
								break;
							}
						}
					}
					// set revised look with removed expired parts
					_lookConverter.playerLookFromLookData( look, closetLook );
				}
			}
		}
		
		/**
		 * Removes expired abilities from player's profile look
		 * @param profile data for one user profile
		 * @param expiredAbilities - Array of expired abilities
		 */
		private function removeExpiredAbilities(profile:ProfileData, profileName:String, expiredAbilities:Array):void
		{
			var specialAbilities:Array = profile.specialAbilities;
			
			// check each special ability
			for (var i:int = specialAbilities.length - 1; i!=-1; i--)
			{
				// limited abilities start with "limited" so trim off
				var abilityId:String = specialAbilities[i].substr(8);;
				
				// if found in expired abilities array
				if (expiredAbilities.indexOf(abilityId) != -1)
				{
					trace(_traceClassName + "removed ability from profile: " + profileName + ": " + abilityId);
					specialAbilities.splice(i, 1);
				}
			}
		}
				
		// TERMINATION FUNCTIONS ////////////////////////////////////////////////////////////////////
		
		/**
		 * Done with handling expired campaigns (whether has any or not)
		 */
		private function doneRemoveExpired():void
		{
			getAdSettingsXML();
		}

		/**
		 * When done processing campaigns
		 * Need this because it gets called after loading local ad data
		 * doneRemoveExpired doesn't get called in that case
		 */
		override protected function doneWithCampaigns():void
		{
			getAdSettingsXML();
		}
		
		/**
		 * get ad settings xml file 
		 */
		private function getAdSettingsXML():void
		{
			// set all arrays to null
			_activeCMSCampaigns = null;
			_expiredProfileCampaigns = null;
			_activeProfileCampaigns = null;
			_activeFilePathList = null;
			_manifestsToDelete = null;
			
			// load ad settings
			var path:String = _fileManager.dataPrefix + AdvertisingConstants.AD_SETTINGS_FILE;
			shellApi.loadXMLFromServerAndAppStorage(path, gotAdSettingsXML);
		}
		
		// UTILITY FUNCTIONS /////////////////////////////////////////////////////////////////////
		
		/**
		 * Get full path to manifest file 
		 * @param campaignName
		 * @return full path
		 */
		private function getManifestPath(campaignName:String):String
		{
			return ("data/" + AdvertisingConstants.AD_PATH_KEYWORD + "/" + campaignName + AdvertisingConstants.MANIFEST_FILE);
		}
		
		private var _traceClassName:String = "MobileStepSetupCampaigns: ";
		private var _fileManager:FileManager;
		private var _allAdTypes:Array;
		
		private var _activeCMSCampaigns:Array;
		private var _activeProfileCampaigns:Array;
		private var _activeFilePathList:Array;
		private var _activeAdCounter:int = 0;
		
		// Campaign deletion
		private var _expiredProfileCampaigns:Array;
		private var _deleteAdCounter:int = 0;
		private var _lookConverter:LookConverter;
		private var _manifestsToDelete:Array;
	}
}
