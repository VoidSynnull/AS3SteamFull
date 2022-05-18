package game.utils
{
	import com.poptropica.AppConfig;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Loader;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.external.ExternalInterface;
	import flash.net.ObjectEncoding;
	import flash.net.SharedObject;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.net.navigateToURL;
	import flash.utils.describeType;
	
	import engine.ShellApi;
	import engine.group.Group;
	import engine.group.Scene;
	import engine.util.Command;
	
	import game.data.ParamList;
	import game.data.TimedEvent;
	import game.data.ads.AdCampaignType;
	import game.data.ads.AdSettingsData;
	import game.data.ads.AdvertisingConstants;
	import game.data.ads.CampaignData;
	import game.data.ads.MessageData;
	import game.data.character.LookConverter;
	import game.data.character.LookData;
	import game.data.profile.ProfileData;
	import game.data.scene.SceneType;
	import game.managers.ads.AdManager;
	import game.managers.ads.AdManagerBrowser;
	import game.proxy.Connection;
	import game.proxy.browser.AdProxyUtils;
	import game.proxy.browser.DataStoreProxyPopBrowser;
	import game.scene.template.SceneUIGroup;
	import game.scene.template.ads.AdInteriorScene;
	import game.scene.template.ads.AdSceneGroup;
	import game.ui.hud.HudPopBrowser;
	import game.ui.saveGame.RealmsRedirectPopup;
	import game.ui.saveGame.SaveGamePopup;
	import game.util.ClassUtils;
	import game.util.DataUtils;
	import game.util.PlatformUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	
	public class AdUtils
	{
		/**
		 * Checks to see if island is standard, essentially not Map, Start, or Custom
		 * Checks against non-island array
		 * @param island
		 * @return Boolean
		 */
		static public function isRealIsland(island:String):Boolean
		{
			if (island == null)
				return false;
			return (AdvertisingConstants.NON_ISLANDS.indexOf(island.toLowerCase()) == -1);
		}
		
		static public function noAds(group:Group):Boolean
		{
			var adManager:AdManager = group.shellApi.adManager as AdManager;
			var noAd:Boolean = (adManager == null);
			if(!noAd) {
				//noAd = !adManager.hasBillboard() && !(adManager.forceMainStreetAdInBillboardScene && adManager.hasMainStreetAd());
				noAd = !adManager.hasMainStreetAd();
			}
			return noAd;
		}
		
		// get campaigns lso
		public static function get campaignsLSO():SharedObject
		{
			var sharedObject:SharedObject = SharedObject.getLocal("ActiveCampaigns", "/");
			sharedObject.objectEncoding = ObjectEncoding.AMF0;
			return(sharedObject);
		}
		
		// convert campaign data to object for LSO
		public static function convertCampaignDataForLSO(data:CampaignData):Object
		{
			var obj:Object = {};
			obj.lockVideo = data.lockVideo;
			if (data.clickUrls != null)
				obj.clickUrls = cleanupCampaignArray(data.clickUrls.convertToArray(), "clickUrl");
			if (data.impressionOnClicks != null)
				obj.impressionOnClicks = cleanupCampaignArray(data.impressionOnClicks.convertToArray(), "impression");
			if (data.impressionUrls != null)
				obj.impressionUrls = cleanupCampaignArray(data.impressionUrls.convertToArray(), "impression");
			return obj;
		}
		
		private static function cleanupCampaignArray(array:Array, elementName:String):Object
		{
			var obj:Object = {};
			for each (var xml:XML in array)
			{
				if (elementName == "clickUrl")
				{
					obj[xml.attribute("id")] = String(xml.valueOf());
				}
				else
				{
					// if impressions
					var impObj:Object = {};
					var elements:XMLList = xml.elements(elementName);
					var len:int = elements.length();
					for (var i:int = 0; i!= len; i++)
					{
						impObj[elements[i].attribute("type")] = String(elements[i].valueOf());
					}
					obj[xml.attribute("id")] = impObj;
				}
			}
			return obj;
		}
		
		/**
		 * Get scene type for scene group 
		 * @param group
		 * @return scene type
		 */
		static public function getSceneType(group:Group):String
		{
			var sceneType:String = SceneType.DEFAULT;
			// if scene and has sceneData, get scene type
			if ((group is Scene) && (Scene(group).sceneData))
				sceneType = Scene(group).sceneData.sceneType;
			return sceneType;
		}
		
		/**
		 * Replace campaign name's suffix, suffix defaults to "Quest"
		 * This is used for mobile for quest campaigns where quest assets exist in their own zip file
		 * Also generates interior photo booth names
		 * @param campaignName - campaign name to change
		 * @param convertToSuffix - String uses as suffix replacement
		 * @param skipInterior - Skip interior and don't add suffix
		 * @return - converted campaign name
		 */
		static public function convertNameToQuest(campaignName:String, convertToSuffix:String = QUEST_SUFFIX, skipInterior:Boolean = false):String
		{
			if (campaignName == null)
			{
				return null;
			}
			// if campaign has photobooth or AR in the name, then append "Interior" to campaign name
			if (campaignName.toLowerCase().indexOf("photobooth") != -1 || campaignName.indexOf("AR") != -1)
			{
				// if Interior not already appended and not skipping interior
				if ((campaignName.indexOf("Interior") == -1) && (!skipInterior))
					campaignName = campaignName + "Interior";
			}
			else
			{
				// if not photo booth
				campaignName = campaignName.replace(MOBILE_MAP_QUEST_SUFFIX, convertToSuffix);
				campaignName = campaignName.replace(MOBILE_BILLBOARD_QUEST_SUFFIX, convertToSuffix);
				campaignName = campaignName.replace(MOBILE_MAINSTREET_QUEST_SUFFIX2, convertToSuffix);
				campaignName = campaignName.replace(MOBILE_MAINSTREET_QUEST_SUFFIX, convertToSuffix);
				campaignName = campaignName.replace(QUEST_SUFFIX, convertToSuffix);
				//campaignName = campaignName.replace("VBB2", "VBB");
			}
			return campaignName;
		}
		/**
		 * Sets up the messaging for an ad, whether it be the building, popup or interior
		 * @param shellApi - for general functional access
		 * @param adData - determining the campaign to determine messaging for
		 * @param container - asset messages are applied to
		 */
		public static function setUpMessaging(shellApi:ShellApi, adData:*, container:DisplayObjectContainer, suffix:String=""):void 
		{
			var campaignData:CampaignData = null;
			
			if(adData is CampaignData) {
				campaignData = adData;
			} else {
				campaignData = shellApi.adManager.getActiveCampaign(adData.campaign_name);
			}
			if(campaignData)
			{
				if(campaignData.messages)
					getMessageTime(shellApi, adData, container, suffix);
			}
		}
		
		private static function getMessageTime(shellApi:ShellApi, adData:*, container:DisplayObjectContainer, suffix:String):void
		{
			trace("AdSceneGroup: setup message change");
			
			// get time from server
			var vLoader:URLLoader = new URLLoader();
			var vRequest:URLRequest = new URLRequest("https://" + shellApi.siteProxy.gameHost + "/time.php");
			vLoader.load(vRequest);
			vLoader.addEventListener(Event.COMPLETE, Command.create(gotTime, shellApi, adData, container));
		}
		
		private static function gotTime(aEvent:Event, shellApi:ShellApi, adData:*, container:DisplayObjectContainer, suffix:String):void
		{
			var serverTime:Number = Number(aEvent.currentTarget.data) * 1000;
			var campaignData:CampaignData = null;
			
			if(adData is CampaignData) {
				campaignData = adData;
			} else {
				campaignData = shellApi.adManager.getActiveCampaign(adData.campaign_name);
			}
			
			// offset for Boston
			var targetLayer:String = getMessaging(campaignData, serverTime);
			var clip:DisplayObject = container[targetLayer+suffix];
			if (clip)
				clip.visible = true;
		}
		
		private static function getMessaging(campaignData:CampaignData, serverTime:Number):String 
		{
			var offset:Number = 5;
			var targetLayer:String = "";
			var targetTime:Number = 0;
			
			if(campaignData.messages == null)
				return targetLayer;
			
			for(var message:String in campaignData.messages) 
			{
				trace(message);
				var mData:MessageData = campaignData.messages[message];
				if(mData.date == "") 
				{
					if (targetTime == 0)
						targetLayer = mData.layer;
				} 
				else 
				{
					var dateArray:Array = mData.date.split("/");
					var date:Date = new Date(dateArray[2], dateArray[0]-1,dateArray[1],offset);
					var vTime:Number = date.time;
					// if message time precedes current time and greater than target time, remember time and layer
					if (vTime < serverTime && vTime > targetTime) 
					{
						targetTime = vTime;
						targetLayer = mData.layer;
						trace("AdSceneGroup: Hours since last message change: " + (serverTime - vTime) / 3600000);
					}
				}
			}
			return targetLayer;
		}
		
		/**
		 * This is used to extract the campaign value from a data object passing a variable name string
		 * @param	campaignData	campaign data object
		 * @name	name			variable name string
		 */
		static public function getCampaignValue(campaignData:Object, name:String):String
		{
			var vValue:String;
			var vSearchName:String = name;
			if (name != null)
			{
				var xmlList:XMLList = describeType(campaignData)..variable;
				trace("campaign properties check against : " + name);
				for(var n:int = 0; n < xmlList.length(); n++)
				{
					var prop:String = xmlList[n].@name;
					trace(prop + ": " + campaignData[prop]);
				}
				// get campaign value by name
				vValue = campaignData[name];
				// if not found then strip off possible number at end
				if (vValue == null)
				{
					name = name.substr(0, -1);
					vValue = campaignData[name];
				}
				// if still not found then add 1 to end and try again
				if (vValue == null)
				{
					name = name + "1";
					vValue = campaignData[name];
				}
			}
			// if still not found then trace error
			if (vValue == null)
				trace("AdUtils :: Can't find value for " + vSearchName);
			return vValue;
		}
		
		/**
		 * Get list of cards from campaign.xml
		 * Filter by gender, web/mobile, and game ID
		 */
		static public function getCardList(shellApi:ShellApi, campaign:String, gameID:String):Vector.<String>
		{
			var cards:Vector.<String> = new Vector.<String>();
			var fullCards:Vector.<String>;
			
			// get campaign data for active campaign (can be MMQ or quest)
			// if MMQ, get cards MMQ location not quest location (quest is not an active campaign for MMQs)
			var campaignData:CampaignData = AdManager(shellApi.adManager).getActiveCampaign(campaign);
			if (campaignData == null)
			{
				trace("GetCardList: Can't find data for campaign " + campaign);
			}
			else
			{
				// if campaign data for campaign
				trace("GetCardList: Getting campaign data for " + campaign); 
				// if cards are found in campaigns.xml for campaign, then they are loaded based on their respective order
				// if female, load girl cards, else load boy cards
				if (shellApi.profileManager.active.gender == SkinUtils.GENDER_FEMALE)
					fullCards =  campaignData.girlcards;
				else
					fullCards = campaignData.boycards;
			}
			// now filter cards
			if (fullCards != null)
			{
				// for each card listed in campaign.xml
				for (var i:int = 0; i != fullCards.length; i++)
				{
					// get card ID
					var cardID:String = fullCards[i];
					// if game ID
					if (gameID != "")
					{
						// get index of game ID in card ID
						var index:int = cardID.indexOf(gameID);
						// if no game ID found, then continue
						if (index == -1)
						{
							trace("GetCardList: no card found with game ID " + gameID);
							continue;
						}
						else
						{
							// else trim off game ID
							// first grab ones flagged for web or mobile
							// if web and card is mobile, then skip it
							if ((!AppConfig.mobile) && (cardID.indexOf(AdvertisingConstants.MobileSuffix) == cardID.length - AdvertisingConstants.MobileSuffix.length))
							{
								trace("GetCardList: skipping card " + cardID);
								continue;
							}
								// if mobile and card is web, then skip it
							else if ((AppConfig.mobile) && (cardID.indexOf(AdvertisingConstants.WebSuffix) == cardID.length - AdvertisingConstants.WebSuffix.length))
							{
								trace("GetCardList: skipping card " + cardID);
								continue;
							}
							// if made it through filter, then add to cards
							cardID = cardID.substr(0, index);
							cards.push(cardID);
						}
					}
					else
					{
						cards.push(cardID);
					}
				}
			}
			return cards;
		}
		
		// MOBILE FUNCTIONS /////////////////////////////////////////////////
		
		/**
		 * Get list of manifest files
		 * @param manifest xml
		 * @param deleteFlag
		 * @param exclude array of files to exclude from final array
		 * @return Array
		 */
		static public function getManifestList(manifest:XML, deleteFlag:Boolean = false, exclude:Array = null):Array
		{
			// create empty list
			var list:Array = [];
			// if not manifest then return empty list
			if (manifest == null)
				return list;
			
			// for each node in manifest
			// each node houses a group of assets with the same path, prefix, & extension
			for each (var node:XML in manifest.children())
			{
				var name:String = String(node.name());
				var assetNodes:XMLList = node.children();
				
				// node is not empty
				if (assetNodes.numChildren != 0)
				{
					var path:String = DataUtils.getNonNullString(node.attribute("path"));
					var prefix:String = DataUtils.getNonNullString(node.attribute("prefix"));
					var extension:String = DataUtils.getNonNullString(node.attribute("ext"));
					var keepFile:Boolean = DataUtils.getBoolean(node.attribute("keep"));
					
					// if extension found, then add dot and extension
					if (extension != "")
						extension = "." + extension;
					
					// if deleting files and keep is true, then continue
					if ((deleteFlag) && (keepFile))
					{
						continue;
					}
					else
					{
						// else add to list
						// for each file
						for each (var asset:XML in assetNodes)
						{
							var fullPath:String = path + prefix + asset.valueOf() + extension;
							// if not deleting or "limited" is in file path, then continue processing
							if ((!deleteFlag) || (fullPath.indexOf(AdvertisingConstants.AD_PATH_KEYWORD) != -1))
							{
								// if no exclude array or not found in exclude array, then add to list
								if ((exclude == null) || (exclude.indexOf(fullPath) == -1))
								{
									list.push(fullPath);
								}
							}
						}
					}
				}
			}
			return list;
		}
		
		// SPONSOR SITE URL FUNCTIONS /////////////////////////////////////////////////
		
		/**
		 * Open sponsor URL (can be pop:// format)
		 * Used by flash wrappers, billboards, ad buildings, and cards
		 * @param shellApi
		 * @param clickURL
		 */
		static public function openSponsorURL(shellApi:ShellApi, clickURL:String, campaignName:String, category:String, id:String):void
		{
			// skip out if invalid URL
			if ((clickURL == null) || (clickURL == ""))
			{
				trace("AdUtils: openSponsorURL: no url found!");
				return;
			}
			
			// get clickURL from campaign data if "campaign.xml"
			// category "Poster": id is poster subchoice
			// category "Video": id is video clip name ("VideoContainer", "VideoContainer1", "blimpVideoContainer")
			// category "Photobooth": no id
			// category "Wrapper": id is "Left" or "Right"
			// category "Popup": id is popup choice ("Start, "Win", "Lose"), "Wishlist", "TrackBuilder", "Photobooth", "Info", "Video"
			// category "PopupGame: id is popup choice ("Start, "Win", "Lose", "Win No Card", "Win Earned Card", "Win Has Card")
			// category "Card": id is card name
			// category "Map": no id
			// category "Carousel": no id
			if (clickURL == AdvertisingConstants.CAMPAIGN_FILE)
			{
				if(campaignName == "ArcadeBotBreakerQuest" || campaignName == "ArcadeStarShooterQuest") {
					campaignName = "AmericanGirlQuest";
				}
				var campaignData:CampaignData = AdManager(shellApi.adManager).getActiveCampaign(campaignName);
				// if campaignData found
				if (campaignData != null)
				{
					// look for match in campaign data clickURLs using county code
					clickURL = findMatchClickURLs(campaignData.clickUrls, AdManager(shellApi.adManager).countryCode, category, id);
					// if no matches found
					if (clickURL == null)
					{
						// then look for match with no country code
						clickURL = findMatchClickURLs(campaignData.clickUrls, "", category, id);
					}
					// if still not found
					if (clickURL == null)
					{
						trace("AdUtils.openSponsorURL: no clickURL found in campaign data for " + campaignName);
						return;						
					}
				}
					// if no campaignData found
				else
				{
					trace("AdUtils.openSponsorURL: no campaign data exists for " + campaignName);
					return;
				}
			}
			
			// replace random text placeholder with actual random number
			if (clickURL.indexOf("[RANDOM]") != -1)
				clickURL = clickURL.split("[RANDOM]").join(String(Math.round(Math.random() * 100000000)));
			if (clickURL.indexOf("[timestamp]") != -1)
				clickURL = clickURL.split("[timestamp]").join(String(Math.round(Math.random() * 100000000)));
			if (clickURL.indexOf("[TIMESTAMP]") != -1)
				clickURL = clickURL.split("[TIMESTAMP]").join(String(Math.round(Math.random() * 100000000)));
			
			// check if pop:// format
			if (clickURL.substr(0,6) == "pop://")
			{
				// split path into array
				var vArray:Array = clickURL.substr(6).split("/");
				trace("Open URL: " + clickURL + " length: " + vArray.length);
				
				// if 2 or more params
				if (vArray.length > 1)
				{
					// if array of 3 items, then can be pop://popup/travelmap/95,90
					// if array of 4 items, then assume form of pop://gameplay/IslandName/SceneName/x,y
					var sectName:String = vArray[0];
					var islandName:String = vArray[1];
					var sceneName:String = vArray[2];
					
					// get coords if passed as forth param
					var coords:String;
					if (vArray.length > 3)
						coords = vArray[3]
					
					trace("AdUtils: OpenSponsorURL scene: " + sceneName);
					
					// if AS3 scene, then load directly (AS2 removed)
					if ((sceneName) && (sceneName.indexOf("game.scenes") != -1))
					{
						// if going to Lands and user is guest, then load AS2 redirectToRegistration scene
						if ((sceneName.indexOf("lab1.Lab1") != -1) && (shellApi.profileManager.active.isGuest))
						{
							trace("AdUtils: going to RedirectToRegistration scene");
							var popup:RealmsRedirectPopup = shellApi.sceneManager.currentScene.addChildGroup(new RealmsRedirectPopup(shellApi.currentScene.overlayContainer)) as RealmsRedirectPopup;
							popup.removed.addOnce(Command.create(checkSaveForRealms, shellApi));
						}
						else
						{
							// TODO :: Want to verify that the Class was valid, before attempting to open - bard
							var sceneParts:Array = sceneName.split(AdvertisingConstants.CAMPAIGN_SCENE_DELIMITER);
							var scene:String = sceneParts[0];
							if(sceneParts.length > 1)// allow map drivers to go to interiors like ad buildings
							{
								var am:AdManager = AdManager(shellApi.adManager);
								am.interiorSuffix = sceneParts[1].substr(14);
								var questName:String = campaignName.replace("MapDriver", "MMSQ");
								am.interiorAd = am.getAdDataByCampaign(questName);
								if(am.interiorAd)
									trace(am.interiorAd.campaign_name);
							}
							var sceneClass:Class = ClassUtils.getClassByName(scene);
							var x:Number = NaN;
							var y:Number = NaN;
							if (coords)
							{
								var coordArr:Array = coords.split(",");
								x = Number(coordArr[0]);
								y = Number(coordArr[1]);
							}
							trace("AdUtils: loadScene: " + scene + " at " + x + "," + y);
							shellApi.loadScene(sceneClass, x, y);
						}
					}
				}
				else
				{
					// if two params or less
					trace("AdUtils :: Error parsing clickURL " + clickURL);	
				}
			}
			else
			{
				// if not pop:// format
				// check for app store URL
				if (clickURL == AdSettingsData.AppleStoreURL)
				{
					// if android, then replace with google play store
					if ( PlatformUtils.isAndroid )
					{
						clickURL = AdSettingsData.GooglePlayStoreURL;
					}
				}
				
				// if mobile, we need delay or else tracking call doesn't get sent
				// because the app sometimes gets removed from memory when going to browser
				if (AppConfig.mobile)
				{
					// use scene UI group instead of scene, because scene is paused when popups are active
					var sceneUIGroup:SceneUIGroup = SceneUIGroup(shellApi.currentScene.groupManager.getGroupById( SceneUIGroup.GROUP_ID ));
					// if no scene UI group as in photobooth, then execute immediately
					if (sceneUIGroup)
						SceneUtil.addTimedEvent(sceneUIGroup, new TimedEvent( 0.25, 1, Command.create(goSponsor, clickURL) ), "openSponsorURL");
					else
						goSponsor(clickURL);
				}
				else
				{
					// if not mobile, then go to URL immediately
					goSponsor(clickURL);
				}
			}
		}
		
		private static function checkSaveForRealms(popup:RealmsRedirectPopup, shellApi:ShellApi):void
		{
			if(popup.save)
				shellApi.currentScene.addChildGroup(new SaveGamePopup(shellApi.currentScene.overlayContainer));
		}
		/**
		 * Find match to campaign data clickURLs with optional country code
		 * @param clickUrls ParamList
		 * @param countryCode
		 * @param category
		 * @param id
		 */
		private static function findMatchClickURLs(clickUrls:ParamList, countryCode:String, category:String, id:String):String
		{
			var foundName:String;
			
			// if country code passed, then add hyphen delimiter
			if (countryCode != "")
				countryCode = "-" + countryCode;
			
			// first look for id with suffix
			var clickURL:String = clickUrls.byId(id + countryCode);
			if (clickURL == null)
			{
				// then look for category with suffix
				clickURL = clickUrls.byId(category + countryCode);
				if (clickURL == null)
				{
					// then look for default with suffix
					clickURL = clickUrls.byId("Default" + countryCode);
					foundName = "Default";
				}
				else
				{
					foundName = category;
				}
			}
			else
			{
				foundName = id;
			}
			if (clickURL != null)
			{
				var message:String = "AdManager.clickURL: using " + foundName + countryCode + " url: " + clickURL;
				trace(message);
				if (ExternalInterface.available) 
					ExternalInterface.call('dbug', message);			
			}
			return clickURL;
		}
		
		/**
		 * Go to sponsor site directly 
		 * @param clickURL
		 */
		static public function goSponsor(clickURL:String):void
		{
			navigateToURL(new URLRequest(clickURL), "_blank");
		}
		
		/**
		 * Splits up multiple URLs in form var1=url&var2=url to an Array
		 * @param aMultipleURL - String in form var1=url&var2=url
		 * @return - Array derived from given URL 
		 */
		static public function parseURLs( aMultipleURL:String ):Array
		{
			// create empty array
			var urlArray:Array = new Array();
			// calculate number of variables
			var total:Number = aMultipleURL.split("&var").length;
			
			// if only one var, then add to array
			// in this case, the URL should NOT be preceded with "var1="
			if (total == 1)
			{
				// strip off var1=
				if (aMultipleURL.substr(0,5) == "var1=")
					aMultipleURL = aMultipleURL.substr(5);
				urlArray.push(aMultipleURL);
			}
			else
			{
				// if multiples
				var endLoc:Number;
				// for each variable
				for (var i:Number = 1; i <= total; i++)
				{
					var findString:String = "var" + i + "=";
					var endString:String = "&var" + (i + 1) + "=";
					// get starting loc
					var loc:Number = aMultipleURL.indexOf(findString);
					// determine ending loc
					if (i != total)
						endLoc = aMultipleURL.indexOf(endString);
					else
						endLoc = aMultipleURL.length;
					// get text in between
					var url:String = aMultipleURL.substring(loc + findString.length, endLoc);
					// add to array
					urlArray.push(url);
				}
			}
			// replace [RANDOM] or [timestamp] with random number
			// check each URL
			for (i = 0; i != total; i++)
			{
				url = urlArray[i];
				// if random placeholder, then replace with actual random number
				if (url.indexOf("[RANDOM]") != -1)
				{
					url = url.split("[RANDOM]").join(String(Math.round(Math.random() * 10000000)));
					urlArray[i] = url;
				}
				if (url.indexOf("[timestamp]") != -1)
				{
					url = url.split("[timestamp]").join(String(Math.round(Math.random() * 10000000)));
					urlArray[i] = url;
				}
				if (url.indexOf("[TIMESTAMP]") != -1)
				{
					url = url.split("[TIMESTAMP]").join(String(Math.round(Math.random() * 10000000)));
					urlArray[i] = url;
				}
			}
			return urlArray;
		}
		
		// BRANDING TIMERS//////////////////////////////////////////////////////
		
		/**
		 * reset all branding timers to inactive at scene start
		 */
		static public function clearBrandingTimers():void
		{
			// get campaign timers LSO (CampaignTimer is legacy lso)
			var campaignTimers:SharedObject = SharedObject.getLocal("CampaignTimers", "/");
			campaignTimers.objectEncoding = ObjectEncoding.AMF0;
			var flush:Boolean = false;
			
			// check to see if the timer should be reset due to a new day starting (midnight passed)
			// find the last time midnight came around
			var currentTime:Date = new Date();
			var lastMidnight:Date = new Date(currentTime.getFullYear(), currentTime.getMonth(), currentTime.getDate(), 0, 0, 0, 0);
			
			// if timers array found
			if (campaignTimers.data.timers)
			{
				// check each timer
				for (var i:int = campaignTimers.data.timers.length - 1; i != -1; i--)
				{
					var timerData:Object = campaignTimers.data.timers[i];
					
					// if the start time was set before the last time midnight came around, reset the timer
					if ( lastMidnight.getTime() > timerData.startTime )
					{
						trace("Branding check: reset for new day for " + timerData.campaign_name);
						// remove timer from array
						campaignTimers.data.timers.splice(i, 1);
						flush = true;
					}
					else if (timerData.active)
					{
						timerData.active = false;
						flush = true;
					}
				}
			}
			if (flush)
				campaignTimers.flush();
		}
		
		/**
		 * Checks if any branded clips should be removed
		 * happens on scene load per ad unit (not in interiors)
		 * @return Boolean indicating campaign has expired
		 */
		static public function checkBranding(group:Group, campaignName:String):Boolean
		{
			// get campaign timers LSO (CampaignTimer is legacy lso)
			var campaignTimers:SharedObject = SharedObject.getLocal("CampaignTimers", "/");
			campaignTimers.objectEncoding = ObjectEncoding.AMF0;
			var flush:Boolean = false;
			var expired:Boolean = false;
			
			// if timers array found
			if (campaignTimers.data.timers)
			{
				// check each timer
				for (var i:int = campaignTimers.data.timers.length - 1; i != -1; i--)
				{
					// get timer with following properties
					// campaign_name:String;
					// startTime:Number; // first run occurred at...
					// active:Boolean; // timer is active and running
					// remainingTime:Number; // remaining time
					var timerData:Object = campaignTimers.data.timers[i];
					
					// if match campaign name, then check timer
					if (timerData.campaign_name == campaignName)
					{
						// if timer has expired, then remove branding but keep timer until tomorrow
						if ( timerData.remainingTime <= 0 )
						{
							trace("Branding check: timer has expired so remove branding " + campaignName);
							// NOTE: sponsored islands have AdSceneGroup2 and AdSceneGroup3 which aren't referenced here
							var adGroup:AdSceneGroup = AdSceneGroup(group.getGroupById(AdSceneGroup.GROUP_ID));
							// if scene has ad group, then remove branding
							if (adGroup)
								adGroup.removeBranding();
							if (timerData.active)
							{
								timerData.active = false;
								flush = true;
							}
							expired = true;
						}
						else
						{
							// if timer is still active
							trace("Branding check: timer is still active for " + campaignName);
							trace("Branding: remaining time for " + campaignName + ": " + timerData.remainingTime);
							// start timer if not already started
							startBrandingTimer(group);
							if (!timerData.active)
							{
								timerData.active = true;
								flush = true;
							}
						}
					}
				}
			}
			if (flush)
				campaignTimers.flush();
			return expired;
		}
		
		/**
		 * Interact with campaign and start branding timer if ad unit has branded clips
		 * Once timer has been started, it should exist in timer array in lso
		 * @param group is current scene
		 * @param campaignName
		 * @param isWrapper
		 */
		static public function interactWithCampaign(group:Group, campaignName:String, isWrapper:Boolean = false):void
		{
			var brandedClips:Array;
			var removeBrandingFunct:Function;
			
			// if wrapper
			if (isWrapper)
			{
				removeBrandingFunct = AdManagerBrowser(group.shellApi.adManager).wrapperManager.clearWrapper;
			}
			else if (group is AdInteriorScene)
			{
				// if ad interior scene
				brandedClips = AdInteriorScene(group).brandedClips;
				removeBrandingFunct = AdInteriorScene(group).removeBranding;
			}
			else
			{
				// if ad units on main street
				// get ad scene group
				// NOTE: sponsored islands have AdSceneGroup2 and AdSceneGroup3 which aren't referenced here
				var adSceneGroup:AdSceneGroup = AdSceneGroup(group.getGroupById(AdSceneGroup.GROUP_ID));
				if(adSceneGroup != null)
				{
					brandedClips = adSceneGroup.brandedClips;
					removeBrandingFunct = adSceneGroup.removeBranding;
				}
			}
			
			// if scene has branded clips or is wrapper
			if ((brandedClips) || (isWrapper))
			{
				var currDate:Date  = new Date();
				var currTime:Number = currDate.getTime();
				var timerData:Object;
				var startTimer:Boolean = true;
				var flush:Boolean = false;
				
				// get campaign timers
				var campaignTimers:SharedObject = SharedObject.getLocal("CampaignTimers", "/");
				campaignTimers.objectEncoding = ObjectEncoding.AMF0;
				
				// if timers array found
				if (campaignTimers.data.timers)
				{
					// check each timer
					for (var i:int = campaignTimers.data.timers.length - 1; i != -1; i--)
					{
						// get timer with following properties
						// campaign_name:String;
						// startTime:Number; // first run occurred at...
						// active:Boolean; // timer is active and running
						// remainingTime:Number; // remaining time
						var testTimer:Object = campaignTimers.data.timers[i];
						
						// if match campaign name
						if (testTimer.campaign_name == campaignName)
						{
							// remember timer object
							trace("BrandingTimer init: found existing branding timer for " + campaignName);
							timerData = testTimer;
							break;
						}
					}
				}
				else
				{
					// if no timers, then create empty array
					campaignTimers.data.timers = [];
					flush = true;
				}
				
				// if no timer object, then create it
				if (timerData == null)
				{
					trace("BrandingTimer init: creating new branding timer for " + campaignName);
					timerData = {};
					timerData.campaign_name = campaignName;
					timerData.startTime = currTime;
					timerData.active = true;
					timerData.remainingTime = AdManager(group.shellApi.adManager).brandingDelay * 60;
					
					// add to timer array
					campaignTimers.data.timers.push(timerData);
					flush = true;
				}
				else
				{
					// if timer already exists
					// if timer has already expired, don't start it
					trace("BrandingTimer init: time left on existing timer " + timerData.remainingTime);
					if (timerData.remainingTime <= 0)
					{
						trace("BrandingTimer init: expired branding timer for " + campaignName);
						removeBrandingFunct();
						startTimer = false;
						if (timerData.active)
						{
							timerData.active = false;
							flush = true;
						}
					}
					else
					{
						trace("BrandingTimer init: ignoring branding timer for " + campaignName);
						if (!timerData.active)
						{
							timerData.active = true;
							flush = true;
						}
					}
				}
				
				if (flush)
					campaignTimers.flush();
				
				// start timer
				if (startTimer)
				{
					trace("Branding: remaining: " + timerData.remainingTime);
					startBrandingTimer(group);
				}
			}
		}
		
		/**
		 * Start branding timer on scene
		 * @param group
		 */
		static private function startBrandingTimer(group:Group):void
		{
			trace("BrandingTimer: start");
			SceneUtil.addTimedEvent(group, new TimedEvent(BRANDING_INCREMENT, 0, Command.create(updateBrandingTimer, group)), "brandingTimer");
		}
		
		/**
		 * Update branding timer every 5 seconds and check if branding should expire 
		 * @param group
		 */
		static private function updateBrandingTimer(group:Group):void
		{
			// get campaign timers LSO (CampaignTimer is legacy lso)
			var campaignTimers:SharedObject = SharedObject.getLocal("CampaignTimers", "/");
			campaignTimers.objectEncoding = ObjectEncoding.AMF0;
			
			var flush:Boolean = false;
			
			// if timers array found
			if (campaignTimers.data.timers)
			{
				// check each timer
				for (var i:int = campaignTimers.data.timers.length - 1; i != -1; i--)
				{
					var timerData:Object = campaignTimers.data.timers[i];
					
					// if active timer (means campaign is on this scene)
					if (timerData.active)
					{
						timerData.remainingTime -= BRANDING_INCREMENT;
						trace("Branding: remaining time for " + timerData.campaign_name + ": " + timerData.remainingTime);
						// if expires
						if (timerData.remainingTime <= 0)
						{
							// remove branding but don't remove from timer array (need to force suppression of branded clips)
							group.shellApi.adManager.track(timerData.campaign_name, "RemovedBranding");
							if (group is AdInteriorScene)
							{
								AdInteriorScene(group).removeBranding();
							}
							else if (group.getGroupById(AdSceneGroup.GROUP_ID))
							{
								// NOTE: sponsored islands have AdSceneGroup2 and AdSceneGroup3 which aren't referenced here
								// if group has main street or billboaqrd AdSceneGroup
								AdSceneGroup(group.getGroupById(AdSceneGroup.GROUP_ID)).removeBranding();
							}
							else
							{
								// if wrapper
								AdManagerBrowser(group.shellApi.adManager).wrapperManager.clearWrapper();
							}
							// make inactive
							timerData.active = false;
						}
						flush = true;
					}
				}
				if (flush)
					campaignTimers.flush();
			}
		}
		
		// TRACKING PIXELS /////////////////////////////////////////////////////
		
		/**
		 * Send tracking pixels to page
		 * @param trackingPixelURL
		 */
		static public function sendTrackingPixels(shellApi:ShellApi, campaignName:String, trackingPixelURL:String, type:String = "Default"):void
		{
			if (trackingPixelURL != null)
			{
				// split any multiple URLs
				var vURLArray:Array = parseURLs(trackingPixelURL);
				for each (var url:String in vURLArray)
				{
					var message:String = "AdManager.trackingPixel: " + campaignName + ": Use " + type + ": " + url;
					trace(message);
					if (ExternalInterface.available) 
						ExternalInterface.call('dbug', message);		
				}
				
				// if mobile
				if (AppConfig.mobile)
				{
					for each (url in vURLArray)
					{
						// if network available, then send pixel
						if (shellApi.networkAvailable())
						{
							sendMobilePixel(url);
						}
						else
						{
							// else cache pixel to LSO
							AdProxyUtils.cacheTrackingPixels(url);
						}
					}
				}
				else
				{
					// if browser
					if (ExternalInterface.available)
						ExternalInterface.call("sendTrackingPixels",vURLArray);
				}
			}	
		}
		
		/**
		 * Send tracking pixel for mobile
		 * @param url
		 */
		static public function sendMobilePixel(url:String):void
		{
			// if mobile and network not available
			url = url + "&popcachebust=" + Math.floor(Math.random() * 10000000);
			trace("AdUtils: sending mobile tracking pixel: " + url);
			var request:URLRequest = new URLRequest(url);
			var loader:Loader = new Loader();
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, pixelLoaded);
			loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, pixelFailed);
			loader.load(request);
		}
		
		/**
		 * When mobile tracking pixel succeeds 
		 * @param e event
		 */
		static private function pixelLoaded(e:Event):void
		{
			e.currentTarget.removeEventListener(Event.COMPLETE, pixelLoaded);
			e.currentTarget.removeEventListener(IOErrorEvent.IO_ERROR, pixelFailed);
			trace("AdUtils :: mobile tracking pixel loaded successfully.");
		}
		
		/**
		 * When mobile tracking pixel fails 
		 * @param e event
		 */
		static private function pixelFailed(e:Event):void
		{
			e.currentTarget.removeEventListener(Event.COMPLETE, pixelLoaded);
			e.currentTarget.removeEventListener(IOErrorEvent.IO_ERROR, pixelFailed);
			trace("AdUtils :: mobile tracking pixel failed to load: " + e);
		}
		
		/**
		 * Removes ad parts from profile for imported look
		 */
		static public function removeAdParts(profile:ProfileData):Boolean
		{
			var profileChanged:Boolean = true;
			
			// remove any ad parts that have "limited" in their name
			// create look converter
			var lookConverter:LookConverter = new LookConverter();		
			// get look for profile
			var look:LookData = lookConverter.lookDataFromPlayerLook( profile.look );
			// list of parts to check
			var partsList:Array = [SkinUtils.MARKS, SkinUtils.MOUTH, SkinUtils.FACIAL, SkinUtils.HAIR, SkinUtils.PANTS, SkinUtils.SHIRT, SkinUtils.OVERPANTS, SkinUtils.OVERSHIRT, SkinUtils.ITEM, SkinUtils.ITEM2, SkinUtils.PACK];
			
			// for each part
			for each (var part:String in partsList)
			{
				var partID:String = look.getValue(part);
				// if part contains "limited"
				if ( (partID) && (partID.indexOf(AdvertisingConstants.AD_PATH_KEYWORD) != -1) )
				{
					// remove part
					if (look.removeLookAspect(part, partID, true) )
					{
						profileChanged = true;
						trace("AdUtils: removed ad part: " + part + " id: " + partID);
					}
				}
			}
			// set revised look with removed ad parts
			lookConverter.playerLookFromLookData( look, profile.look );
			
			//////////////////////////////////////////////////////////
			
			// remove any special abilities for ads
			var specialAbilityDatas:Array = profile.specialAbilities;
			// check each special ability
			for (var i:int = specialAbilityDatas.length - 1; i!=-1; i--)
			{
				var ability:XML = specialAbilityDatas[i];
				
				// if has parameters
				if (ability.parameters)
				{
					// for each param
					for each (var param:String in ability.parameters.children())
					{
						// if param has "limited", then it is an ad item so remove the ability
						if (param.indexOf(AdvertisingConstants.AD_PATH_KEYWORD) != -1)
						{
							profileChanged = true;
							trace("AdUtils: removed ad ability: id: " + ability.@id);
							specialAbilityDatas.splice(i,1);
							break;
						}
					}
				}
			}
			return profileChanged;
		}
		
		// SAVING SCORES //////////////////////////////////////////////////
		
		static public function setScore(shellApi:ShellApi, score:Number, gameName:String = null, onComplete:Function = null):void
		{
			var profile:ProfileData = shellApi.profileManager.active;
			
			// get lowercase arcade game name if not passed
			if (gameName == null)
			{
				gameName = shellApi.arcadeGame.toLowerCase();
			}
			
			// if not guest
			if (!shellApi.profileManager.active.isGuest)
			{
				// set params to send to server
				var vars:URLVariables = new URLVariables();
				vars.login = profile.login;		// login name
				vars.pass_hash = profile.pass_hash;	// password hash
				vars.dbid = profile.dbid;			// database ID
				vars.gamename = gameName;			// game name
				vars.score = score;					// final score
				//vars,level = 0; 					// game level
				vars.win = 1; 						// number of wins
				vars.loss = 0; 						// number of losses
				vars.game_time = 0;					// game time (not used)
				vars.personal_high_score = 100;		// personal high score (seems the db keeps track of personal high scores without sending this)
				vars.category = "all_time_highscore";	// score category
				
				// we don't store battle ranking in profile
				//vars.battle_ranking = super.shellApi.profileManager.active.battle_ranking;
				
				// make php call to server
				// note: credits are added on the back end when this php script is called
				shellApi.logWWW("Adutils :: setScore - not guest, setting score of: " + vars.score + " for game: " + vars.gamename);  
				var connection:Connection = new Connection();
				connection.connect(shellApi.siteProxy.secureHost + "/games/interface/submit_game.php", vars, URLRequestMethod.POST, Command.create(sendScoreCallback, shellApi, onComplete), Command.create(sendScoreError, onComplete));
			}
			// if guest, then save to shared object
			else
			{
				var so:SharedObject = SharedObject.getLocal("arcade", "/");
				so.objectEncoding = ObjectEncoding.AMF0;
				if (so.data[gameName] == null)
				{
					so.data[gameName] = score;
					so.flush();
				}
				else if (score > so.data[gameName])
				{
					so.data[gameName] = score;
					so.flush();
				}
			}
		}
		
		/**
		 * When submit_game.php callback is received from server 
		 * @param e
		 */
		static private function sendScoreCallback(e:Event, shellApi:ShellApi, onComplete:Function):void
		{
			trace("sendScoreCallback Success: " + e.target.data);
			// should return "answer=ok&credits=10"
			// parse data
			var return_vars:URLVariables = new URLVariables(e.target.data);
			var credits:int = 0;
			if (return_vars.answer == "ok")
			{
				// update credits
				trace("sendScoreCallback Credits: " + return_vars.credits);
				credits = int(DataUtils.getNumber(return_vars.credits));
				shellApi.arcadePoints += credits;
			}
			if(onComplete)
			{
				onComplete();
			}
		}
		
		/**
		 * If error when calling submit_game.php
		 * @param e
		 */
		static private function sendScoreError(e:IOErrorEvent, onComplete:Function):void
		{
			trace("SendScore error: " + e.errorID);
			if(onComplete)
			{
				onComplete();
			}
		}		
		
		static public const QUEST_SUFFIX:String 					= "Quest"; 
		static public const MOBILE_MAP_QUEST_SUFFIX:String 			= "MMQ"; // mobile map quest
		static public const MOBILE_BILLBOARD_QUEST_SUFFIX:String 	= "MBBQ"; // mobile billboard quest
		static public const MOBILE_MAINSTREET_QUEST_SUFFIX:String 	= "MMSQ"; // mobile main street quest
		static public const MOBILE_MAINSTREET_QUEST_SUFFIX2:String 	= "MMSQ2"; // mobile main street quest
		
		static private const BRANDING_INCREMENT:int = 5; // how often the timer (in seconds) checks for expired branding
	}
}