package game.managers.ads
{
	import com.poptropica.AppConfig;
	import com.poptropica.interfaces.IPlatform;
	import com.poptropica.platformSpecific.android.AmazonPlatform;
	import com.poptropica.platformSpecific.android.AndroidPlatform;
	import com.poptropica.platformSpecific.ios.IosPlatform;
	
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.external.ExternalInterface;
	import flash.geom.Point;
	import flash.net.ObjectEncoding;
	import flash.net.SharedObject;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.system.Capabilities;
	import flash.utils.Dictionary;
	
	import ash.core.Entity;
	
	import engine.Manager;
	import engine.ShellApi;
	import engine.components.Spatial;
	import engine.data.AudioWrapper;
	import engine.group.Group;
	import engine.group.Scene;
	import engine.managers.SoundManager;
	import engine.systems.AudioSystem;
	import engine.util.Command;
	
	import game.adparts.AdNpcFriend;
	import game.components.hit.Door;
	import game.components.ui.CardItem;
	import game.data.ParamData;
	import game.data.ParamList;
	import game.data.ads.AdCampaignType;
	import game.data.ads.AdData;
	import game.data.ads.AdParser;
	import game.data.ads.AdSettingsData;
	import game.data.ads.AdTrackingConstants;
	import game.data.ads.AdvertisingConstants;
	import game.data.ads.CampaignData;
	import game.data.ads.PlayerContext;
	import game.data.comm.PopResponse;
	import game.data.scene.DoorData;
	import game.data.scene.SceneType;
	import game.data.ui.card.CardAction;
	import game.data.ui.card.CardButtonData;
	import game.data.ui.card.CardItemData;
	import game.managers.ProfileManager;
	import game.managers.SceneManager;
	import game.managers.interfaces.IAdManager;
	import game.proxy.Connection;
	import game.proxy.DataStoreProxyPop;
	import game.proxy.DataStoreRequest;
	import game.proxy.IDataStore2;
	import game.proxy.PopDataStoreRequest;
	import game.proxy.browser.AdProxyUtils;
	import game.scene.template.MiniGameGroup;
	import game.scene.template.PhotoBoothGroup;
	import game.scene.template.PlatformerGameScene;
	import game.scene.template.SceneUIGroup;
	import game.scene.template.ads.AdBaseGroup;
	import game.scene.template.ads.AdBlimpGroup;
	import game.scene.template.ads.AdScavengerItemGroup;
	import game.scene.template.ads.AdSceneGroup;
	import game.scene.template.ads.AdSceneGroup2;
	import game.scene.template.ads.AdSceneGroup3;
	import game.scene.template.ads.AdVendorCartGroup;
	import game.scene.template.ui.CardGroup;
	import game.systems.scene.DoorSystem;
	import game.ui.popup.LeavingPopBumper;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.ClassUtils;
	import game.util.DataUtils;
	import game.util.EntityUtils;
	import game.util.ProxyUtils;
	import game.util.SceneUtil;
	import game.utils.AdUtils;
	
	import org.osflash.signals.Signal;
	
	/**
	 * Base ad manager class 
	 * @author VHOCKRI
	 */
	public class AdManager extends Manager implements IAdManager
	{		
		// ad manager is created only if ads are active
		public function AdManager()
		{
		}
		
		// INITIALIZATION FUNCTIONS /////////////////////////////////////////////////////////////////////////
		
		/**
		 * Initialize ad manager
		 * @param adTypes supported ad types
		 */
		public function init(adTypes:Array):void
		{
			trace("AdManager: init: ads are served from: " + (shellApi.siteProxy as DataStoreProxyPop).gameHost);
			
			// save vars
			_adTypes = ( adTypes != null ) ? adTypes : [];
			
			// init objects
			// active campaigns are used to store card data
			_activeCampaigns = new Dictionary(true);
			// cms campaigns are used to store CMS ad data across all islands
			_cmsCampaigns = new Vector.<AdData>();
			// capped campaigns
			_cappedCampaigns = new Vector.<AdData>();
			//_allowSwapBillboard = false; // will be overriden by AdSettings.xml
			
			// init activity timer
			_activityTimer = new ActivityTimer();
			shellApi.injector.injectInto(_activityTimer);
			
			// attach listener for whenever a new scene is loaded
			shellApi.sceneManager.sceneLoaded.add(handleSceneLoaded);
			
			// flash campaigns LSO
			if (!AppConfig.mobile)
			{
				var campaigns:SharedObject = AdUtils.campaignsLSO;
				campaigns.clear();
				AdProxyUtils.cleanOutCampaignData();
			}
			
			var connection:Connection = new Connection();
			connection.connect(shellApi.siteProxy.secureHost + "/get_country_code.php", null, URLRequestMethod.POST, gotCountryCode);
		}
		
		/**
		 * Handler for retrieval of ad settings xml.
		 * @param xml
		 */
		public function gotAdSettingsXML(xml:XML):void
		{
			trace("AdManager: ad settings: " + xml);
			// parse ad settings data
			_adSettings = AdSettingsData.parse(xml);
			// set allow swap billboard flag
			/*
			if (AppConfig.mobile)
				_allowSwapBillboard = _adSettings.forceMSinBBMobile;
			else
				_allowSwapBillboard = _adSettings.forceMSinBB;
			*/
			// set carousel delay
			_carouselDelay = _adSettings.carouselDelay;
			// set carousel delay
			_minibillboardDelay = _adSettings.minibillboardDelay;
			// set bumper delay
			_bumperDelay = _adSettings.bumperDelay;
			// get branding delay
			_brandingDelay = _adSettings.brandingDelay;
		}
		
		// when country code returned from server
		private function gotCountryCode(event:Event):void
		{
			trace("Country Code: " + event.currentTarget.data);
			var code:String = String(event.currentTarget.data);
			if ((code != null) && (code != ""))
			{
				_countryCode = code;
			}
		}
		
		/**
		 * prep scene by setting up ad manager vars
		 * called from Scene
		 * @param scene
		 */
		public function prepSceneForAds(scene:Scene):void
		{
			// clear branding timers
			AdUtils.clearBrandingTimers();
			
			// remember if last scene was interior scene
			_wasInteriorScene = _isInteriorScene;
			
			// reset vars
			_campaignStreetType = "";
			_isInteriorScene = false;
			_shortIslandMain = false;
			_offMain = true;
			_allowRemainingAds = [];
			_adsLoaded = [];
			_hasAdBuilding = false;
			
			var initFriend:Boolean = false;
			
			// get scene type
			_sceneType = AdUtils.getSceneType(scene);
			trace( "AdManager: prepSceneForAds: scene: " + scene + " of scene type: " + _sceneType );
			
			// set vars based on scene type
			switch (_sceneType)
			{
				case SceneType.SHORTMAIN:
					_offMain = false;
					_shortIslandMain = true;
					break;
				case SceneType.ADINTERIOR:
					_isInteriorScene = true;
					initFriend = true;
					break;
				case SceneType.MAINSTREET:
					_offMain = false;
					_campaignStreetType = _mainStreetType;
					initFriend = true;
					break;
				case SceneType.BILLBOARD:
					// force to main street type
					_campaignStreetType = _mainStreetType;
					initFriend = true;
					break;
			}
			
			// if plaformer game scene supports NPC friends, then setup NPC friend object
			// need this even for mobile, if only to turn off the NPC placeholders in the scene
			// if scene supports NPC friend, then initialize
			if ((initFriend) && (shellApi.island != "map"))
			{
				_npcFriend = new AdNpcFriend();
				_npcFriend.init(PlatformerGameScene(scene), shellApi);
			}
			else
			{
				// else set NPC friend to null
				_npcFriend = null;
			}
			// complete setup once the scene is ready
			scene.ready.addOnce(setupNPCFriend);
			
			// determine default state for current scene
			_defaultOffMain = _offMain;
			// swappable indicates scene can swap billboards/main street ads and vice-versa
			//_swappable = false;
			
			try
			{
				// get scene name
				var vScene:String = ClassUtils.getNameByObject((shellApi.getManager(SceneManager) as SceneManager).currentScene);
				if( DataUtils.validString(vScene) )
				{
					// set adMixed to be on main as default
					if (vScene.indexOf("::AdMixed") != -1)
					{
						_defaultOffMain = false;
						//_swappable = true;
					}
						// set billboards to be off Main as default
					else if ((vScene.indexOf("::AdStreet") != -1) || (vScene.indexOf("::AdGround") != -1) || (vScene.indexOf("::AdDeadEnd") != -1))
					{
						_defaultOffMain = true;
						//_swappable = true;
					}
				}
			} 
			catch(error:Error) 
			{
				trace("AdManger: prepSceneForAds: issue retrieving current Scene, error: " + error.message );
			}
		}
		
		/**
		 * Setup NPC friend on scene 
		 * @param group
		 */
		private function setupNPCFriend(group:Group):void
		{
			// setup NPC friend if object created for main street
			// this is needed even if no ad buildings are loaded
			// note that if NPC FRIEND is not supported (as on mobile), npc friends are disabled and deleted
			var npcSupported:Boolean = (_adTypes.indexOf(_npcFriendType) != -1 );
			// if NPC friend created because scene supports it, then setup
			if (_npcFriend)
				_npcFriend.setup(npcSupported, _npcFriendType);
		}
		
		// FUNCTIONS TO BE OVERRIDEN ///////////////////////////////////////////////////////////
		
		/**	
		 * Triggered on every scene load and handles ad timer and autocards - can be overridden
		 * Assumes that we already have CMS data for island
		 * @param scene
		 */
		protected function handleSceneLoaded(scene:Group):void
		{
			// if photobooth island, then return
			if (shellApi.island == "photoBoothIsland")
				return;
			
			// if not ad interior
			if (!_isInteriorScene) 
			{
				endActivityTimer();
			}
			else
			{
				// if interior
				// clear return to interior flag
				_returnToInterior = false;
			}
			
			// check for autocards or scavenger items on main street
			if (!_offMain || (Scene(scene)).groupPrefix.indexOf("americanGirl/mainStreet")!= -1)
			{
				testAutoCard();
				checkScavengerItem(Scene(scene));
			}
		}
		
		// AD GROUP FUNCTIONS ///////////////////////////////////////////////////////////////////////////////////////
		
		/**
		 * Checks scene type, adds an AdGroup if scene type qualifies for one
		 * Called by PlatformerGameScene
		 * @param scene
		 * @param callback - If scene qualifies for ad callback triggered on AdGroup's completion
		 * @return Boolean
		 */
		public function checkAdScene(scene:Scene, callback:Function):Boolean
		{
			trace("check ad scene");
			// has main street or billboard or vendor cart ad
			var hasAds:Boolean = false;
			
			// init number of ads on scene to zero
			_totalSceneAds = 0;
			_sceneAdCounter = 0;
			
			// remember callback
			_adsReadyCallback = callback;
			
			// if not interior scene
			// NOTE: ad interior is NOT an ad scene that loads a billboard or main street ad
			if (!_isInteriorScene)
			{
				// if main street or billboard
				if ((_sceneType == SceneType.MAINSTREET) || (_sceneType == SceneType.BILLBOARD))
				{
					// create and validate ad scene group
					if (createAdGroup(scene))
					{
						_totalSceneAds++;
						hasAds = true;
					}
					
					// if main street
					if (_sceneType == SceneType.MAINSTREET)
					{
						// if lego island, then check for 2nd and 3rd ad buildings
						// add sponsored islands here (lowercase)
						if (shellApi.island == "lego" || shellApi.island == "americanGirl" || shellApi.sceneName == "Town")
						{
							if (createAdGroup(scene, 2))
							{
								_totalSceneAds++;
								hasAds = true;
							}
							if (createAdGroup(scene, 3))
							{
								_totalSceneAds++;
								hasAds = true;
							}
						}
						// create and validate vendor cart group
						if (createVendorCartGroup(scene))
						{
							_totalSceneAds++;
							hasAds = true;
						}
						// create and validate photo booth group
						if (createPhotoBoothGroup(scene))
						{
							_totalSceneAds++;
							hasAds = true;
						}
						
						// create and validate mini-game group
						if(createMiniGameGroup(scene))
						{
							_totalSceneAds++;
							hasAds = true;
						}
						
						// check for blimp takeover
						if(createBlimpGroup(scene))
						{
							_totalSceneAds++;
							hasAds = true;
						}
					}
				}
			}
			
			// return true if has ads
			// if true, then framework waits for ads to get added to scene before calling addGroups
			return (hasAds);
		}
		
		/**
		 * Create and add an ad scene group to scene
		 * @param scene
		 * @param callback
		 */
		protected function createAdGroup(scene:Scene, num:int = 1):Boolean
		{
			var adGroup:AdSceneGroup;
			switch (num)
			{
				case 1:
					adGroup = new AdSceneGroup(null, this);
					break;
				case 2:
					adGroup = new AdSceneGroup2(null, this);
					break;
				case 3:
					adGroup = new AdSceneGroup3(null, this);
					break;
			}
			// prep adGroup
			var hasAd:Boolean = adGroup.prepAdGroup(PlatformerGameScene(scene));
			// if has ad
			if (hasAd)
			{
				trace( "AdManager: createAdGroup: adding AdGroup to scene: " + scene );
				// add adGroup to scene
				scene.addChildGroup(adGroup);
				// setup callback for when adGroup is completed
				adGroup.ready.addOnce(adsReady);
				// setup NPCs when scene is ready
				scene.ready.addOnce(adGroup.processNPCs);
			}
			return hasAd;
		} 
		
		/**
		 * Create and add a vendor cart group to scene
		 * @param scene
		 */
		protected function createVendorCartGroup(scene:Scene):Boolean
		{
			var vcGroup:AdVendorCartGroup = new AdVendorCartGroup(null, this);
			// prep adGroup
			var hasAd:Boolean = vcGroup.prepAdGroup(PlatformerGameScene(scene));
			// if has ad
			if (hasAd)
			{
				trace( "AdManager: createVendorCartGroup: adding AdVendorCart group to scene: " + scene );
				// add adGroup to scene
				scene.addChildGroup(vcGroup);
				// setup callback for when adGroup is coompleted
				vcGroup.ready.addOnce(adsReady);
			}
			return hasAd;
		}
		
		/**
		 * Create and add a photo booth group to scene
		 * @param scene
		 */
		protected function createPhotoBoothGroup(scene:Scene):Boolean
		{
			var pbGroup:PhotoBoothGroup = new PhotoBoothGroup(null, this);
			// prep adGroup
			var hasAd:Boolean = pbGroup.prepAdGroup(PlatformerGameScene(scene));
			// if has ad
			if (hasAd)
			{
				trace( "AdManager: createPhotoBoothGroup: adding PhotoBooth group to scene: " + scene );
				// add adGroup to scene
				scene.addChildGroup(pbGroup);
				// setup callback for when adGroup is coompleted
				pbGroup.ready.addOnce(adsReady);
			}
			return hasAd;
		}
		
		protected function createMiniGameGroup(scene:Scene):Boolean
		{
			var mgGroup:MiniGameGroup = new MiniGameGroup(null, this);
			var hasAd:Boolean = mgGroup.prepAdGroup(PlatformerGameScene(scene));
			
			if(hasAd)
			{
				trace("AdManager: createMiniGameGroup: adding MiniGame group to scene: " + scene);
				scene.addChildGroup(mgGroup);
				mgGroup.ready.addOnce(adsReady);
			}
			
			return hasAd;
		}
		
		protected function createBlimpGroup(scene:Scene):Boolean
		{
			var blimpGroup:AdBlimpGroup = new AdBlimpGroup(null, this);
			var hasAd:Boolean = blimpGroup.prepAdGroup(PlatformerGameScene(scene));
			
			if(hasAd)
			{
				trace("AdManager: createBlimpGroup: adding Blimp group to scene: " + scene);
				scene.addChildGroup(blimpGroup);
				blimpGroup.ready.addOnce(adsReady);
			}
			
			return hasAd;
		}
		
		protected function checkScavengerItem(scene:Scene):Boolean
		{
			var hasAd:Boolean = false;
			if (scene is PlatformerGameScene)
			{
				var scavengerItemGroup:AdScavengerItemGroup = new AdScavengerItemGroup(null, this);
				hasAd = scavengerItemGroup.prepAdGroup(PlatformerGameScene(scene));
			
				if(hasAd)
				{
					trace("AdManager: checkScavengerItem: adding scavenger item group to scene: " + scene);
					scene.addChildGroup(scavengerItemGroup);
					scavengerItemGroup.ready.addOnce(adsReady);
				}
			}
			return hasAd;
		}
		
		/**
		 * When mainstreet/billboard ad and/or vendor cart is ready
		 * @param adGroup
		 */
		private function adsReady(adGroup:AdBaseGroup):void
		{
			// if no ads then let framework know ads are done
			if (_totalSceneAds == 0)
				_adsReadyCallback();
			else
			{
				// if ads
				// increment ad counter
				_sceneAdCounter++;
				trace("AdManager: ad groups completed: " + _sceneAdCounter + " of " + _totalSceneAds);
				// when all ads loaded then let framework know ads are ready
				if (_sceneAdCounter == _totalSceneAds)
					_adsReadyCallback();
			}
		}
		
		// AD DATA FUNCTIONS ///////////////////////////////////////////////////////////////////////
		
		/**
		 * Determines ads/campaigns associated with a given island
		 * This only needs to happen once per island
		 * @param island - AS3 island id [ format example: "Carrot" ]
		 * @param types - array of ad types applicable to island
		 * @param complete - callback function
		 */
		public function getCampaignsForIsland(island:String, types:Array, complete:Function):void
		{	
			_nextIsland = island;
			// if ad types not specified then use defaults
			if (types == null) { types = _adTypes; }
			
			switch(island)
			{
				// if hub island, then need carousel and theater poster and home popup types added
				case "Hub":
					types.push(_carouselType);
					types.push(_theaterPosterType);
					types.push(_homePopupType);
					types.push(_theater);
					types.push(_mainStreetType + " 2");
					break;
				
				// add sponsored islands here
				// add additional main street ads
				case "Lego":
					types.push(_mainStreetType + " 2");
					types.push(_mainStreetType + " 3");
					break;
				case "AmericanGirl":
					types.push(_mainStreetType + " 2");
					types.push(_mainStreetType + " 3");
					break;
			}
			
			trace("AdManager: getCampaignsForIsland: Get campaigns: island: " + island + ", types: " + types);
			
			// if real island (not Map, Start, Custom) then remember this island (to be used for ad interiors)
			// need to know what islannd to return to
			if (AdUtils.isRealIsland(island))
			{
				_lastIsland = island;
				// inventory tracking for autocards if new real island
				track(AdTrackingConstants.AD_INVENTORY, AdTrackingConstants.TRACKING_AD_SPOT_PRESENTED, _autocardType, island);
			}
			
			// pull new list of active campaigns in case network wasn't available before or new ads turned on
			// not needed for web
			if ((AppConfig.mobile) && (shellApi.networkAvailable()) && (AppConfig.adsFromCMS))
			{
				// make AMFPHP call to server to get campaign names for records that require campaign.xml
				var req:DataStoreRequest = PopDataStoreRequest.MobileCampaignsXMLRequest();
				req.requestTimeoutMillis = 2000;
				(shellApi.siteProxy as IDataStore2).call(req, processCampaignsWithXML);
			}

			// get AS2 island name
			_as2Island = ProxyUtils.convertIslandToAS2Format(island);
			
			// if mobile and network not available, then we cannot retrieve campaign info
			if ( (AppConfig.mobile) && (!shellApi.networkAvailable()) && (!AppConfig.debug) )
			{
				trace("AdManager: getCampaignsForIsland: CMS not available for mobile");
				complete();
			}
			else
			{	
				// if network available
				// Check to see if required ad types for island are already accounted for
				// Ad types not accounted for will remain in requiredAdTypes Array and will be requested from CMS
				var requiredAdTypes:Array = types.concat();
				var adData:AdData;
				var typeIndex:int;
				var i:int = _cmsCampaigns.length-1;
				// for each ad in CMS campaigns array
				for (i; i > -1; i--) 
				{
					// get ad data from CMS campaigns array
					adData = _cmsCampaigns[i];
					// if island matches
					if ( adData.island == _as2Island )
					{
						// if existing ad has required ad type, then delete from required ad types array
						typeIndex = requiredAdTypes.indexOf(adData.campaign_type);
						if( typeIndex != -1 )
						{
							requiredAdTypes.splice(typeIndex,1);
							if( requiredAdTypes.length == 0 )
							{
								// if all ad types are accounted for, then nothing needs to be retrieved
								complete();
								return;
							}
						}
					}
				}
				
				// if need to pull ads from CMS
				if (AppConfig.adsFromCMS)
				{
					if (shellApi.networkAvailable())
					{
						trace("AdManager: getCampaignsForIsland: Get campaigns: AS2 island: " + _as2Island + ", final types: " + requiredAdTypes);
						// setup callback for when CMS returns data
						_cmsCompleteSignal.addOnce(complete);
						// get required ads from CMS
						pullCampaignsFromCMS(island, requiredAdTypes);
					}
					else
					{
						// if network not available
						trace("AdManager: getCampaignsForIsland: CMS not available");
						complete();
					}
				}
				else
				{
					// if not needing to pull from CMS, then pull from local xml file (for debugging)
					trace("AdManager: getCampaignsForIsland: using local xml data for testing");
					// In case of local testing, we assign current island to AdData
					// This allows for all islands to share the same AdData
					for each (adData in _cmsCampaigns)
					{
						adData.island = _as2Island;
					}
					complete();
				}
			}
		}
		
		/**
		 * Get campaign data from CMS for one ad type
		 * Used when ad hits frequency cap and we need a new ad to take its place
		 * @param island
		 * @param types Array of ad types to pull from CMS
		 */
		public function getCampaignFromCMS( island:String, types:Array):void
		{
			// if network not available, then skip
			if ( !shellApi.networkAvailable() )
			{
				trace("AdManager: getCampaignFromCMS: CMS not available");
			}
			else if ( AppConfig.adsFromCMS )
			{
				// if need to pull ads from CMS
				trace("AdManager: getCampaignFromCMS: get campaigns from CMS for AS3 island: " + island + ", types: " + types);
				// clear signal
				_cmsCompleteSignal.removeAll();
				// get CMS campaign for one ad type
				pullCampaignsFromCMS(island, types);
			}
		}
		
		/**
		 * Request campaigns from CMS.
		 * @param island AS3 island ID
		 * @param types array of ad types
		 */
		private function pullCampaignsFromCMS( island:String, types:Array ):void
		{
			function codeForPlatform(platform:IPlatform):String
			{
				var platformCode:String = 'Other';
				if (Capabilities.playerType == 'ActiveX' || Capabilities.playerType == 'PlugIn') {
					platformCode = 'Desktop/Laptop';
				} else {	// not in browser
					if (platform is AmazonPlatform) {
						platformCode = 'Amazon';
					} else if (platform is AndroidPlatform) {
						platformCode = 'AndroidOS';
					} else if (platform is IosPlatform) {
						platformCode = 'iOS';
					}
				}
				return platformCode;
			}
			// get server format for AS3 island
			var islandAS3ForServer:String = ProxyUtils.convertIslandToServerFormat(island);
			
			// as3 island name won't work for these because the CMS doesn't append "_as3" to the island names
			switch (_as2Island)
			{
				// add sponsored islands here
				case "Lego":
				case "Map":
					islandAS3ForServer = _as2Island;
					break;
			}
			
			var platform:String = codeForPlatform(shellApi.platform);
			trace("AdManager: pullCampaignsFromCMS: pull campaigns for island: " + islandAS3ForServer + " for platform: " + platform + " for ad types: " + types );
			// check for any capped campaigns and pass this to server call
			var cappedCampaigns:Array = AdProxyUtils.getCappedCampaigns(this);
			
			// get age from profile (age can be zero in desktop mode in FLashBuilder)
			// RLH: we also want to allow an age of zero for live testing
			// originaly, the code forced an age of zero to 6 years old
			var age:int = shellApi.profileManager.active.age;
			
			// get gender from profile
			var gender:String = ProxyUtils.convertGenderToServerFormat(shellApi.profileManager.active.gender);
			
			// make AMFPHP call to server to get campaigns
			// note: default of country="" is sent to call (added when PlayerContext initialized)
			var playerContext:PlayerContext = new PlayerContext( age, gender, islandAS3ForServer, types, cappedCampaigns);
			var req:DataStoreRequest = PopDataStoreRequest.playerCampaignsRequest(playerContext);
			req.requestData.playerContext.platform = platform;
			req.requestTimeoutMillis = 5000;
			(shellApi.siteProxy as IDataStore2).call(req, getCampaignsCallback);
		}
		
		/**
		 * When data comes back from CMS
		 * @response response from server
		 */
		private function getCampaignsCallback(response:PopResponse):void
		{
			// if failure
			if (!response.succeeded)
			{
				track(AdTrackingConstants.AD_FAILURE, "Ad Callback Failure");
				// if response error is null, we ignore it
				if (response.error == null)
				{
					trace("AdManager: getCampaignsCallback: null response (ignored)");
					return;
				}
				trace("AdManager: getCampaignsCallback error: " + response );
				_cmsCompleteSignal.dispatch();
			}
			else
			{
				// if success
				// objects passed: status, error, on_main, off_main, cache
				// if response has on_main and off_main objects
				if ((response.data.on_main) && (response.data.off_main))
				{
					trace("AdManager: getCampaignsCallback: success");					
					// parse returned ad data
					var parser:AdParser = new AdParser();
					var dataArray:Vector.<AdData> = parser.parseAMFPHP(response.data, _as2Island);
					// update cms campaign array with new parsed ad data
					updateAdData(dataArray);
					_cmsCompleteSignal.dispatch();
				}
				else
				{
					// if missing data
					trace("AdManager: getCampaignsCallback: on_main and off_main objects missing.");
					_cmsCompleteSignal.dispatch();
				}
			}
		}
		
		/**
		 * Process response when retrieving campaign names for records requiring campaign.xml
		 */
		public function processCampaignsWithXML(response:PopResponse = null):void
		{
			if (response == null)
			{
				trace("AdManager: processCampaignsWithXML: null response");
			}
			// if failure
			else if (!response.succeeded)
			{
				// if response error is null, we ignore it
				if (response.error == null)
				{
					trace("AdManager: processCampaignsWithXML: null response (ignored)");
				}
				trace("AdManager: processCampaignsWithXML failure: " + response );
			}
			else
			{
				// if success
				if (response.data)
				{
					trace("AdManager: processCampaignsWithXML: success " + response.data);
					var index:uint = 0;
					// iterate through names
					if (response.data[0] != null)
					{
						while (true)
						{
							var campaignName:String = response.data[index];
							if (campaignName == null)
								break;
							// trim off alias
							var pos:int = campaignName.indexOf("|");
							if (pos != -1)
							{
								campaignName = campaignName.substr(0,pos);
							}
							// load campaign xml if haven't yet
							if (getActiveCampaign(campaignName) == null)
							{
								trace("AdManager: processCampaignsWithXML: get campaign.xml for " + campaignName);
								getCampaignXML(campaignName, true);
							}
							index++;
						}
					}
				}
				else
				{
					// if missing data
					trace("AdManager: processCampaignsWithXML: empty array.");
				}
			}	
		}
		
		/**
		 * Update campaigns with new campaign data
		 * @param dataArray array of AdData
		 */
		public function updateAdData(dataArray:Vector.<AdData>):void
		{
			// add new data to both campaign lists
			for each (var adData:AdData in dataArray)
			{
				makeAdDataCampaignsActive(adData);
			}
			trace("AdManager: adding " + dataArray.length + " more campaigns. Total:" + _cmsCampaigns.length);			
			// save to LSO also
			AdProxyUtils.saveCampaignsToLSO(dataArray);
		}
		
		/**
		 * Add campaigns to array of CMS campaigns
		 * Create new CampaignData, add to active campaigns list, and load campaign xml for parsing
		 * @param adData
		 */
		public function makeAdDataCampaignsActive(adData:AdData):void
		{
			// if mobile and campaign doesn't have campaign.xml loaded then return
			if ((AppConfig.mobile) && (adData.clickURL == AdvertisingConstants.CAMPAIGN_FILE) && (getActiveCampaign(adData.campaign_name) == null))
			{
				trace("AdManager: campaign.xml not loaded: suppressing campaign: " + adData.campaign_name);
				return;
			}
			
			// remove any existing ad data in desired slot (prevents duplication)
			removeAdData(adData.island, adData.campaign_type, adData.offMain);
			
			// add to cms campaigns array
			_cmsCampaigns.push(adData);
			trace("AdManager: adding campaign: " + adData.campaign_name);
			
			// now add to active campaigns
			// skip wrappers, carousel and ad drivers, scavenger items, home popups, and mini-billboards because they don't have cards
			switch(adData.campaign_type)
			{
				case AdCampaignType.WRAPPER:
				case AdCampaignType.PHOTO_BOOTH_INTERIOR:
				case AdCampaignType.APP_OF_THE_DAY:
				case AdCampaignType.WEB_SCAVENGER_ITEM:
				case AdCampaignType.WEB_HOME_POPUP:
				case AdCampaignType.THEATER:
					return;
			}
			// exclude map types, carousel types, static mini-billboard types, and theater poster types
			if (adData.campaign_type.indexOf(AdCampaignType.WEB_MAP_AD_BASE) == 0)
				return;
			//if (adData.campaign_type.indexOf(AdCampaignType.MOBILE_MAP_AD_BASE) == 0)
			//	return;
			if (adData.campaign_type.indexOf("Carousel") != -1)
				return;
			if (adData.campaign_type.indexOf("300x250") != -1)
				return;
			if (adData.campaign_type.indexOf("Poster") != -1)
				return;

			// create array of campaign names (converted) - don't add Interior to campaign names
			var campaignsForAdData:Array = [AdUtils.convertNameToQuest(adData.campaign_name, AdUtils.QUEST_SUFFIX, true)];
			// if autocards, then parse into multiple campaigns, as needed
			if (adData.campaign_type.indexOf(AdCampaignType.AUTOCARD) != -1)
				campaignsForAdData = AdUtils.parseURLs(adData.campaign_name);
			
			// for each campaign name
			var campaignData:CampaignData;
			for each (var campaignName:String in campaignsForAdData)
			{
				if (campaignName)
				{
					// check if campaign is in active campaign list, if not then create CampaignData and add to list of active campaigns
					if (getActiveCampaign(campaignName) == null)
					{
						trace("AdManager: loading campaign.xml for " + campaignName);
						// load campaign.xml file and parse when loaded
						getCampaignXML(campaignName, false);
					}
				}
				else
				{
					trace("AdManager: Error: null campaign name for ad type: " + adData.campaign_type);
				}
			}
		}
		
		// DOOR FUNCTIONS //////////////////////////////////////////////////////////////////////////////
		
		/**
		 * When door is reached in scene
		 * Used for checking if door to ad interior
		 * @param charEntity
		 * @param doorEntity
		 * @param destination
		 * 
		 */
		public function doorReached(charEntity:Entity, doorEntity:Entity):void
		{
			// door entity data
			var doorData:DoorData = doorEntity.get(Door).data;
			
			//arcade takeover
			if(doorData.destinationScene == "ArcadeTakeover")
			{
				var adData:AdData = shellApi.adManager.getAdData(AdCampaignType.ARCADE_TAKEOVER,true);
				super.shellApi.logWWW("AdManager :: doorReached - arcade takeover");
				if(adData)
				{
					super.shellApi.logWWW("AdManager :: doorReached - found ad data" + adData.campaign_file2);
					AdManager(shellApi.adManager).interiorSuffix = adData.campaign_file2;
					AdManager(shellApi.adManager).interiorAd = adData;
					doorData.destinationScene = "game.scenes.custom.partyRoom.PartyRoom";
					//shellApi.loadScene(PartyRoom);
				}
				else
				{
					super.shellApi.logWWW("AdManager :: doorReached - no ad data");
					doorData.destinationScene = "game.scenes.hub.starcade.Starcade";
				}
			}
			else
			{
				// if going to AS2 ad interior, then start timer and save scene to LSO
				if (doorData.destinationScene.indexOf("Global") != -1)
				{
					// start timer
					// AS3 interiors start timer when AdInteriorScene loads
					startActivityTimer(doorData.campaignName);
				}
				
				// get adData for campaign attached to door
				_interiorAd = getAdDataByCampaign(doorData.campaignName);
				if(_interiorAd)
					trace(_interiorAd.campaign_name);
				
				// check for quest door entrance
				// sample destination scene
				// game.scenes.custom.questInterior.QuestInterior|campaignScene=GalacticHotDogsQuest_Interior
				// strip off anything that follows delimiter and use that
				var dest:Array = doorData.destinationScene.split(AdvertisingConstants.CAMPAIGN_SCENE_DELIMITER);
				doorData.destinationScene = dest[0];
				// if going to interior
				if(dest[1])
				{
					// lock input while scene loads (needed for mobile)
					SceneUtil.lockInput(shellApi.currentScene, true);
					_interiorSuffix = dest[1].substr(14);
				}
				else
				{
					_interiorSuffix = "";
				}
				// if returning from quest interior and going back to entrance scene, then used saved entrance data
				if ((doorData.destinationScene == DoorSystem.PREVIOUS_SCENE) && (_entranceScene))
				{
					doorData.destinationScene = _entranceScene;
					doorData.destinationSceneX = _entranceSceneX;
					doorData.destinationSceneY = _entranceSceneY;
					doorData.destinationSceneDirection = _entranceSceneDirection;
					// clear entrance
					_entranceScene = null;
				}
			}
		}
		
		/**
		 * Save scene when going into quest interior, called from getAds and queueAdContent
		 * Since we don't save ad scene locations, we only need to save to active memory
		 * TODO: Should/Does this get saved to local memeory? - bard
		 */
		public function saveSceneForEntrance():void
		{
			var scene:Scene = shellApi.sceneManager.currentScene;
			trace( "AdManager: saveSceneForEntrance: current scene: " + scene);
			// save current scene so we can return to it
			_entranceScene = ClassUtils.getNameByObject(scene);
			
			// if player has position, then save it
			var position:Point = EntityUtils.getPosition(shellApi.player);
			// note that position is null, when on Map scene
			if(position != null)
			{
				_entranceSceneX = int(position.x);
				_entranceSceneY = int(position.y);
				_entranceSceneDirection = ( shellApi.player.get(Spatial).scaleX > 0 ) ? CharUtils.DIRECTION_LEFT : CharUtils.DIRECTION_RIGHT;
			}
		}
		
		// INVENTORY CARD FUNCTIONS ////////////////////////////////////////////////////////////
		
		/**
		 * Apply campaign data to card data for card actions and tracking
		 * @param cardData
		 * @param callBack
		 */
		public function cardApplyCampaign( cardData:CardItemData, callBack:Function = null):void
		{
			var buttonData:CardButtonData;
			var cardAction:CardAction;
			var i:int;
			var j:int;
			
			// check card type
			switch(cardData.type)
			{
				// if store card
				case CardGroup.STORE:
					// for each button
					for (i = 0; i < cardData.buttonData.length; i++)
					{
						buttonData = cardData.buttonData[i];
						
						// for each action
						for (j = 0; j < buttonData.actions.length; j++) 
						{
							cardAction = buttonData.actions[j];
							
							// check for tracking
							if( DataUtils.validString(cardAction.tracking) )
							{
								// if found, then create tracking for card action
								buttonData.actions.push( createAdTrackingAction(cardData.name, cardAction, cardAction.type) );
								j++;
							}
						}
					}
					// trigger callback if provided
					if (callBack)
						callBack();
					return;
					
				case CardGroup.CUSTOM: // if campaign card
					// apply campaign data to card data
					// if we have campaign data for card
					// cards for quests need to use campaign quest name (end with "Quest")
					var campaignData:CampaignData = getActiveCampaign( cardData.campaignId );
					if( campaignData != null)
					{
						// add campaign data to card
						cardData.campaignData = campaignData;
						
						var paramData:ParamData;
						// for each button
						for (i = 0; i < cardData.buttonData.length; i++) 
						{
							buttonData = cardData.buttonData[i];
							
							// for each action
							for (j = 0; j < buttonData.actions.length; j++) 
							{
								cardAction = buttonData.actions[j];
								
								// if action type = "gotoUrl" then apply url value from campaignData to action's param value
								if (cardAction.type == cardAction.GO_TO_URL)
								{
									// add click tracking
									var param:ParamData = new ParamData();
									param.id = CardGroup.EVENT_TYPE;
									if ((cardAction.params != null) && ( cardAction.params.getParamId("useClickedForTracking")))
										param.value = AdTrackingConstants.TRACKING_CLICKED;
									else
										param.value = AdTrackingConstants.TRACKING_CLICK_TO_SPONSOR;
									if (cardAction.params == null)
										cardAction.params = new ParamList();
									cardAction.params.push( param );
									
									// add subchoice tracking
									param = createCardSubChoice(cardAction.tracking, cardData.name);
									cardAction.params.push( param );
								}
								else
								{
									// if action is not gotoURL (tracking triggered in gotoUrl function in cardGroup)
									// check for tracking
									if( DataUtils.validString(cardAction.tracking) )
									{
										// if found, then create tracking for other types of card actions
										buttonData.actions.push( createAdTrackingAction(cardData.name, cardAction) );
										j++;
									}
								}
							}
						}
						// trigger callback if provided
						if (callBack)
							callBack();
					}
					else
					{
						// if campaign data not found, then try to load campaign.xml and parse and call this function again
						if (cardData.campaignId)
						{
							trace( "AdManager: " + cardData.campaignId + " card campaign data is not available.");
							var path:String = AdvertisingConstants.AD_PATH_KEYWORD + "/" + cardData.campaignId + "/" + AdvertisingConstants.CAMPAIGN_FILE;
							shellApi.loadFile(shellApi.dataPrefix + path, Command.create(gotCampaignCardXML, cardData, callBack));
						}
						else
						{
							trace( "AdManager: Error: campaign name is null for card " + cardData.id);
						}
					}
					return;
					
				default:
					trace("AdManager: card is not a store or campaign card!");
					// trigger callback if provided
					if (callBack)
						callBack();
					return;
			}
		}
		
		/**
		 * When campaign.xml file is loaded for campaign card
		 * @param xml
		 * @param cardData
		 * @param callBack
		 */
		private function gotCampaignCardXML(xml:XML, cardData:CardItemData, callBack:Function = null):void
		{
			// if xml if valid
			if ((xml != null) && (xml != ""))
			{
				// create campaign data
				var campaignData:CampaignData = new CampaignData( xml );
				// set campaign name
				campaignData.campaignId = cardData.campaignId;
				// add to active campaigns
				addActiveCampaign( campaignData );
				trace( "AdManager: xml loaded for card: created campaign for " + cardData.campaignId);
				// apply to card data
				cardApplyCampaign(cardData);
			}
			else
			{
				// if xml is invalid
				// this will trigger when the xml is not found on server
				trace( "AdManager: failed to create campaign for " + cardData.campaignId);
			}
			if (callBack)
				callBack();
		}
		
		// CARD TRACKING FUNCTIONS ///////////////////////////////////////////////////////////
		
		/**
		 * Create a new TRACK_CAMPAIGN type action based on an action within a campaign card
		 * @param seedAction card action
		 * @param eventType
		 * @return cardAction
		 */
		private function createAdTrackingAction( cardName:String, seedAction:CardAction, eventType:String = null):CardAction
		{
			// create new card action
			var trackingAction:CardAction = new CardAction();
			// set action type to track
			trackingAction.type = trackingAction.TRACK;
			// add new params
			trackingAction.params = new ParamList();
			
			// if event type not passed
			if (eventType == null)
			{
				// check action type of seed action and set event type
				switch (seedAction.type)
				{
					case seedAction.OPEN_VIDEO_POPUP:
						eventType = AdTrackingConstants.TRACKING_OPENED_POPUP;
						break;
					default:
						eventType = AdTrackingConstants.TRACKING_CLICKED;
						break;
				}
			}
			
			// add click tracking using event type above
			var param:ParamData = new ParamData();
			param.id = CardGroup.EVENT_TYPE;
			param.value = eventType;
			trackingAction.params.push( param );
			
			// add subchoice tracking
			param = createCardSubChoice(seedAction.tracking, cardName);
			trackingAction.params.push( param );
			
			return trackingAction;
		}
		
		private function createCardSubChoice(tracking:String, cardName:String):ParamData
		{
			// add choice tracking
			var param:ParamData = new ParamData();
			param.id = CardGroup.EVENT_SUBCHOICE;
			// use card name if tracking is "true"
			if (tracking == "true")
				tracking = cardName;
			param.value = tracking;
			return param;
		}
		
		/**
		 * Trigger tracking when card collected 
		 * @param cardItem
		 */
		public function trackCardCollected( cardItem:CardItem ):void
		{
			// if card is missing data
			if ((cardItem == null) || (cardItem.cardData == null) || (cardItem.cardData.campaignData == null)) 
			{
				trace ("AdManager: trackCardCollected: CardItem or CardData is null, most likely due to card XML not being found.");
			}
			else
			{
				// if card data if valid, then track
				track(cardItem.cardData.campaignId, AdTrackingConstants.TRACKING_OBJECT_COLLECTED, "Card", cardItem.cardData.name);
			}
		}
		
		// CAMPAIGN TRACKING FUNCTIONS ////////////////////////////////////////////////////////////////////////////////////////
				
		/**
		 * This is used for making all campaign tracking calls
		 * @param campaignName
		 * @param event
		 * @param choice
		 * @param subChoice
		 * @param numValLabel
		 * @param numVal
		 * @param count number of aggregated tracking calls
		 */
		public function track(campaignName:String, event:String, choice:String = null, subChoice:String = null, numValLabel:String = null, numVal:Number = NaN, count:String = null):void
		{
			// if ad spot presented and CMG, add suffix
			if ((event == AdTrackingConstants.TRACKING_AD_SPOT_PRESENTED) && (shellApi.cmg_iframe))
				event += "CMG";
			
			// track main street conversions for desktop
			if ((!AppConfig.mobile) && (event == AdTrackingConstants.TRACKING_IMPRESSION) && (choice == AdCampaignType.MAIN_STREET))
			{
				var url:String = "//www.googleadservices.com/pagead/conversion/1071789230/?label=EU3qCM6mg2UQrumI_wM&amp;guid=ON&amp;script=0";
				AdUtils.sendTrackingPixels(shellApi, "MainStreetConversion", url);
				track("MainStreetConversion", "MainStreetConversion", shellApi.island);
			}

			// if not ad inventory, then trigger any third-party impressions
			if ((campaignName != AdTrackingConstants.AD_INVENTORY) && (campaignName != AdTrackingConstants.AD_FAILURE))
			{
				// get ad data for campaign name
				var adData:AdData = getAdDataByCampaign(campaignName);
				
				// send tracking pixels based on match to event
				var matchName:String = AdUtils.convertNameToQuest(campaignName);
				var campaignData:CampaignData = _activeCampaigns[matchName];
				if (campaignData)
				{
					// check for third party impressions with country code
					if (!checkThirdPartyImpressions(campaignName, campaignData, _countryCode, event, choice, subChoice))
					{
						// if not found then check without country code
						if (!checkThirdPartyImpressions(campaignName, campaignData, "", event, choice, subChoice))
						{
							// if no third party impressions found at all and AdImpression event
							if (event == AdTrackingConstants.TRACKING_IMPRESSION)
							{
								if (adData != null)
								{
									// send tracking pixels if provided in CMS
									AdUtils.sendTrackingPixels(shellApi, campaignName, adData.impressionURL);
								}
							}
						}
					}
				}
				// if no active campaign found and AdImpression or MapImpression
				else if ((event == AdTrackingConstants.TRACKING_IMPRESSION) || (event == AdTrackingConstants.TRACKING_MAP_IMPRESSION))
				{
					if (adData != null)
					{
						// send tracking pixels if provided in CMS
						AdUtils.sendTrackingPixels(shellApi, campaignName, adData.impressionURL, event);
					}
				}
			}
			
			// add island to ad inventory calls unless autocard
			if ((campaignName == AdTrackingConstants.AD_INVENTORY) && (choice.indexOf(AdCampaignType.AUTOCARD) == -1))
				subChoice = shellApi.island;
			
			// append "Web" or "Mobile" suffix to campaign name if not ad inventory and not already suffixed
			if ((campaignName != AdTrackingConstants.AD_INVENTORY) && (campaignName != AdTrackingConstants.AD_FAILURE) && (campaignName.indexOf(AdvertisingConstants.CAMPAIGN_ALIAS_DELIMITER) == -1))
			{
				var suffix:String;
				var unbranded:Boolean = false;
				
				// if adData, then get suffix
				if (adData != null)
				{
					suffix = adData.suffix;
					unbranded = adData.unbranded;
				}
				// if no suffix or empty suffix, then clear suffixs
				if ((!suffix) || (suffix == "")) {
					//if (AppConfig.mobile)
					//	suffix = AdvertisingConstants.MobileSuffix;
					//else
					//	suffix = AdvertisingConstants.WebSuffix;
					suffix = "";
				} else {
					// if have standard web or mobile suffix, clear suffix
					if ((suffix == AdvertisingConstants.MobileSuffix) || (suffix == AdvertisingConstants.WebSuffix)) {
						suffix = "";
					}
				}
				// if campaign is unbranded, then add Unbranded suffix
				if (unbranded)
					campaignName += "Unbranded";
				// now add suffix if exists
				if (suffix != "") {
					campaignName += (AdvertisingConstants.CAMPAIGN_ALIAS_DELIMITER + suffix);
				}
			}
			
			// force null values to empty strings
			if (choice == null)
				choice = "";
			if (subChoice == null)
				subChoice = "";
			
			// set up label/value pair, if any
			var vPair:String = "";
			if (numValLabel != null)
				vPair = ", " + numValLabel + "=" + numVal;
			
			// force quest campaign name for interior
			if (_isInteriorScene)
				campaignName = AdUtils.convertNameToQuest(campaignName);
			
			var tracking:String = "AdManager.trackCampaign: campaign: " + campaignName + ", event: " + event + ", choice: " + choice + ", subchoice: " +  subChoice + vPair;
			trace(tracking);
			if (ExternalInterface.available) 
				ExternalInterface.call('dbug', tracking);			
			
			shellApi.track(event, choice, subChoice, campaignName, numValLabel, numVal, count);
			
			// keep a top level counter of all impressions.
			event = event.toLowerCase();
			if (event.indexOf("impression") > -1)
			{
				shellApi.track("AdvertisingImpression");
				shellApi.track("AdvertisingImpressionTest");
			}
		}
		
		/**
		 * Check for third party impressions with optional country code
		 * @param campaignName
		 * @param campaignData
		 * @param countryCode
		 * @param event
		 * @param choice
		 * @param subChoice
		 */
		private function checkThirdPartyImpressions(campaignName:String, campaignData:CampaignData, countryCode:String, event:String, choice:String, subChoice:String):Boolean
		{
			var type:String = "Default";
			var xml:XML;
			
			// if country code passed, then add hyphen delimiter
			if (countryCode != "")
				countryCode = "-" + countryCode;
			
			// impressions on click
			if (event == AdTrackingConstants.TRACKING_CLICK_TO_SPONSOR)
			{
				if (campaignData.impressionOnClicks != null)
				{
					xml = campaignData.impressionOnClicks.byId(subChoice + countryCode);
					if (xml != null)
					{
						type = subChoice;
					}
					else
					{
						xml = campaignData.impressionOnClicks.byId(choice + countryCode);
						if (xml != null)
						{
							type = choice;
						}
					}
				}
			}
			else
			{
				// if other events
				if (campaignData.impressionUrls != null)
				{
					trace("tracking: searching on subchoice: " + subChoice);
					xml = campaignData.impressionUrls.byId(subChoice + countryCode);
					if (xml != null)
					{
						type = subChoice;
					}
					else
					{
						trace("tracking: searching on choice: " + choice);
						xml = campaignData.impressionUrls.byId(choice + countryCode);
						if (xml != null)
						{
							type = choice;
						}
						else
						{
							trace("tracking: searching on event: " + event);
							xml = campaignData.impressionUrls.byId(event + countryCode);
							if (xml != null)
							{
								type = event;
							}
						}
					}
				}
			}
			if (xml != null)
			{
				trace("tracking: found xml: " + xml);
				var trackingPixels:String = "";
				var list:XMLList = xml.elements("impression");
				var length:int = list.length();
				for (var i:int = 0; i != length; i++)
				{
					switch (String(list[i].attribute("type")))
					{
						case "standard":
							trackingPixels += ("var" + (i+1) + "=" + list[i].valueOf());
							break;
						case "moat":
							if (AppConfig.mobile)
								continue;
							else
								trackingPixels += ("var" + (i+1) + "=" + list[i].valueOf());
							break;
						case "moatClass":
							if (AppConfig.mobile)
								continue;
							else
								trackingPixels += ("var" + (i+1) + "=" + "pop://no.script?" + list[i].valueOf());
							break;
						default:
							trackingPixels += ("var" + (i+1) + "=" + list[i].valueOf());
							break;
					}
					if ((i < length - 1) && (length > 1))
						trackingPixels += "&";
				}
				AdUtils.sendTrackingPixels(shellApi, campaignName, trackingPixels, type + countryCode);
				return true;
			}
			else
			{
				return false;
			}
		}
		
		// ACTIVITY TIMER FUNCTIONS /////////////////////////////////////////////////////////////////////////
		
		/**
		 * Start activity timer
		 * @param isInterior Boolean
		 */
		public function startActivityTimer(campaignName:String, isInterior:Boolean = false):void
		{
			trace("AdManager campaign started: " + campaignName);
			if (ExternalInterface.available) 
				ExternalInterface.call('dbug', "AdTimer started for " + campaignName);			
			// initialize activity timer with new campaign
			_activityTimer.initialize(campaignName);
			// needed for case when coming from AS2 ad building to AS3 interior
			// also needed when going to AS2 for force the timer to end for all AS3 campaigns
			if (!AppConfig.mobile)
				_activityTimer.addScene("AS3Scene");
		}
		
		/**
		 * Tell activity timer to end
		 */
		private function endActivityTimer():void
		{
			// clear campaign with timer
			trace("AdManager campaign cleared");
			// initialize activity timer with no campaign (this stops the timer)
			_activityTimer.initialize("");
		}
		
		// AUTOCARD FUNCTIONS //////////////////////////////////////////////////////////////////
		
		/**
		 * Test if autocard in supported
		 */
		protected function testAutoCard():void
		{
			// if autocard supported for this build, trigger autocard after 1 second delay
			if (_adTypes.indexOf(_autocardType) != -1)
			{
				SceneUtil.delay(shellApi.sceneManager.currentScene, 1, awardAutoCards);
			}
		}
		
		/**
		 * Award auto cards
		 */
		private function awardAutoCards():void
		{
			// fetch autocard data
			var adData:AdData = getAdData(_autocardType, _offMain, true);
			// if found
			if (adData != null)
			{
				var cards:String;
				
				// get cards. If mobile the cards should be listed in the file2 field in the CMS UPDATE - removed field 1 since same campaign is pulled for mobile and web
				//	if// (AppConfig.mobile)
					//cards = adData.campaign_file2;
				//	else
				cards = adData.campaign_file2;
				// parse multiples
				var cardsArr:Array = cards.split(',');
				if ((cardsArr.length == 0) || (cardsArr[0] == ""))
				{
					trace("+++++++++++++ERROR: autocard is missing card number in CMS!");
					return;
				}
				trace("AdManager: award autocards: " + cardsArr);
				//var campaigns:Array = AdUtils.parseURLs(adData.campaign_name);
				var numCards:int = cardsArr.length;
				// for each card
				for (var i:int=0; i!=numCards; i++)
				{
					// don't trigger tracking if already have card
					// if don't have card yet, then track
					if (!shellApi.checkHasItem(cardsArr[i], CardGroup.CUSTOM))
						track(adData.campaign_name, AdTrackingConstants.TRACKING_IMPRESSION, AdCampaignType.AUTOCARD);
					// get card and animate
					shellApi.getItem(cardsArr[i], CardGroup.CUSTOM, true);
				}
			}
		}
		
		// AD DATA FUNCTIONS //////////////////////////////////////////////////////////////////////////
		
		/**
		 * Get campaign adData object based on ad type and on/off main
		 * @param adType
		 * @param offMain
		 * @param saveToLSO Boolean
		 * @param island
		 * @return AdData
		 */
		public function getAdData(adType:String, offMain:Boolean = false, saveToLSO:Boolean = false, island:String = null):AdData
		{
			// if island not passed, then set to AS3 island
			if (island == null)
				island = _as2Island;
			if (island)
			{
				trace("AdManager: getting campaign for type: " + adType + ", offMain: " + offMain + ", island: " + island);
				
				//for each (var ad:AdData in _cmsCampaigns)
				for (var i:int = _cmsCampaigns.length-1; i!= -1; i--)
				{
					var ad:AdData = _cmsCampaigns[i];
					
					// if match to island, ad type and on/off main
					// trace("island: " + ad.island + ", type: " + ad.campaign_type + ", offmain: " + ad.offMain);
					if ((ad.island == island) && (ad.campaign_type == adType) && (ad.offMain == offMain))
					{
						// if saving campaign to LSO
						if (saveToLSO)
						{
							// add campaign name for saved ad
							_adsLoaded.push(ad.campaign_name);
							// if main street or billboard ad, then flag as scene with ad building
							//if ((ad.campaign_type == _mainStreetType) || (ad.campaign_type == _billboardType))
							if (ad.campaign_type == _mainStreetType)
								_hasAdBuilding = true;
							
							// save to LSO and get the number over the cap count (default is -1)
							var overCapCount:int = AdProxyUtils.saveCampaignToLSO(ad, island, this);
							trace("AdManager: " + ad.campaign_name + " campaign is over frequency cap count by " + overCapCount);
							
							// if cap reached or exceeded
							if (overCapCount >= 0)
							{
								// get frequency cap campaign group
								var frequencyCapGroup:int = ad.campaign_cap_group;
								// if no campaign group
								if (frequencyCapGroup == 0)
								{
									// if exceeded cap, then return null
									if (overCapCount > 0)
									{
										trace("AdManager: suppressing ad because frequency cap exceeded");
										return null;
									}
								}
								else
								{
									// if campaign group
									// if just reaching cap
									if (overCapCount == 0)
									{
										trace("AdManager: campaign group has just reached its frequency cap: " + frequencyCapGroup);
									}
									else
									{
										// if exceeded cap
										// if cap group is not listed in allowed list, then suppress ad
										if (_allowRemainingAds.indexOf(frequencyCapGroup) == -1)
										{
											trace("AdManager: suppressing group ad because frequency cap reached");
											return null;
										}
										else
										{
											trace("AdManager: displaying subsequent group ad because frequency cap was reached on this scene");											
										}
									}
								}
								// remove from cms campaign list (new campaign will load when time period expires)
								removeAdData(island, adType, offMain, true);
								removeAdDataByName(ad.campaign_name, true);
							}
							// if main street ad and not custom island then save to custom island
							// needed for main street ads with doors (but some don't have doors such as MVUs)
							if ((adType == _mainStreetType) && (island != AdvertisingConstants.AD_ISLAND))
								AdProxyUtils.saveCampaignToCustomIsland(ad.campaign_name);
							return ad;
						}
						else
						{
							// if not saving to LSO
							return ad;
						}
					}
				}
			}
			trace("AdManager: campaign not found for " + adType);
			
			// if saving and not mobile
			/* // this is causing problems
			if ((saveToLSO) && (!AppConfig.mobile))
			{
			// check for expired capped ads
			var expiredAdTypes:Array = AdProxyUtils.checkExpiredCappedCampaigns();
			// if any expired capped ads
			if (expiredAdTypes.length != 0)
			{
			trace("AdManager: getAdData: pulling new campaigns from CMS to replace frequency capped ads: " + expiredAdTypes);
			// can't do this on mobile because ad zips are loaded only when going to new islands
			getCampaignFromCMS(island, expiredAdTypes);
			}
			}
			*/
			return null;
		}
		
		/**
		 * Get campaign adData object based on campaign name
		 * @param campaignName
		 * @return AdData
		 */
		public function getAdDataByCampaign(campaignName:String):AdData
		{
			//for each (var ad:AdData in _cmsCampaigns)
			for (var i:int = _cmsCampaigns.length-1; i != -1; i--)
			{
				var ad:AdData = _cmsCampaigns[i];
				
				// if match to campaign name
				if (ad.campaign_name == campaignName)
					return ad;
			}
			
			// check capped ad data
			// need this for capped campaigns when campaign data has been deleted
			//for each (var ad:AdData in _cmsCampaigns)
			for (i = _cappedCampaigns.length-1; i != -1; i--)
			{
				ad = _cappedCampaigns[i];
				
				// if match to campaign name
				if (ad.campaign_name == campaignName)
					return ad;
			}

			trace("AdManager: getAdDataByCampaign: campaign not found for " + campaignName);
			return null;
		}
		
		/**
		 * Remove campaign AdData from list of campaigns based on island, ad type and on/off main
		 * @param island
		 * @param adType
		 * @param offMain
		 * @param isCapping campaign is being capped
		 */
		public function removeAdData(island:String, adType:String, offMain:Boolean, isCapping:Boolean = false):void
		{
			//for each (var ad:AdData in _cmsCampaigns)
			for (var i:int = _cmsCampaigns.length-1; i != -1; i--)
			{
				var ad:AdData = _cmsCampaigns[i];
				// if match to island, ad type and on/off main, then delete
				if ((ad.island == island) && (ad.campaign_type == adType) && (ad.offMain == offMain))
				{
					// add to capped list if not already in list
					if ((isCapping) && (!isCappedAd(ad.campaign_name)))
						_cappedCampaigns.push(ad);
					trace("AdManager: deleting campaign for island: " + island + " type: " + adType + " offMain: " + offMain);
					// remove from cms list
					_cmsCampaigns.splice(i,1);
				}
			}
		}
		
		/**
		 * Remove campaign AdData from list of campaigns based on campaignName
		 * @param campaignName
		 * @param isCapping campaign is being capped
		 */
		public function removeAdDataByName(campaignName:String, isCapping:Boolean = false):void
		{
			//for each (var ad:AdData in _cmsCampaigns)
			for (var i:int = _cmsCampaigns.length-1; i != -1; i--)
			{
				var ad:AdData = _cmsCampaigns[i];
				// if match to campaign name but not capped campaign, then delete
				if ((ad.campaign_name == campaignName) && (ad.type != AdvertisingConstants.CAPPED_TYPE))
				{
					// add to capped list if not already in list
					if ((isCapping) && (!isCappedAd(ad.campaign_name)))
						_cappedCampaigns.push(ad);
					trace("AdManager: deleting campaign: " + campaignName);
					// remove from cms list
					_cmsCampaigns.splice(i,1);
				}
			}
		}
		
		/**
		 * Remove all campaign AdDatas associated with given island from list of campaigns
		 * @param island
		 * @param isCapping campaign is being capped
		 */
		public function removeAdDataByIsland(island:String, isCapping:Boolean = false):void
		{
			trace("AdManager: deleting campaigns for island: " + island);
			//for each (var ad:AdData in _cmsCampaigns)
			for (var i:int = _cmsCampaigns.length-1; i!= -1; i--)
			{
				var ad:AdData = _cmsCampaigns[i];
				// if match island, then delete
				if (ad.island == island)
				{
					// add to capped list if not already in list
					if ((isCapping) && (!isCappedAd(ad.campaign_name)))
						_cappedCampaigns.push(ad);
					// remove from cms list
					_cmsCampaigns.splice(i,1);
				}
			}
		}
		
		/**
		 * Check if capped campaign
		 * @param campaignName
		 * @return boolean
		 */
		private function isCappedAd(campaignName:String):Boolean
		{
			for (var i:int = _cappedCampaigns.length-1; i!= -1; i--)
			{
				var ad:AdData = _cappedCampaigns[i];
				// if campaign names match
				if (ad.campaignName == campaignName)
				{
					return true;
				}
			}
			return false;
		}
		
		/**
		 * Get ad data for carousel slot 
		 * @param num
		 * @return AdData
		 */
		public function getCarouselSlot(num:int):AdData
		{
			return getAdData(_carouselType + " " + num, false);
		}
		/**
		 * Get ad data for minibillboard slot 
		 * @param num
		 * @return AdData
		 */
		public function getMiniBillboardSlot(num:int,island:String=null,types:Array=null):AdData
		{
			if(island != null)
				pullCampaignsFromCMS(island,types);
			return getAdData(_minibillboardType + " " + num, false);
		}
		
		/**
		 * Get ad data for home popup 
		 * @param num
		 * @return AdData
		 */
		public function getHomePopup():AdData
		{
			// get ad data for home popup if any
			var adData:AdData = getAdData(_homePopupType, false);
			// if data found, then set boolean and pass data
			if (adData != null)
			{
				var adName:String = adData.campaign_name;
				trace("home popup: " + adName);
				// suppress on CMG if no cmg 
				if ((adName.indexOf("NoCMG") != -1) && (shellApi.cmg_iframe))
				{
					return null;
				}
				// suppress on Poptropica if CMG only
				else if ((adName.indexOf("CMGOnly") != -1) && (!shellApi.cmg_iframe))
				{
					return null;
				}
				else
				{
					trace("home popup not suppressing");
					// if guest then show and don't save
					if (shellApi.profileManager.active.isGuest)
					{
						trace("home popup: is guest, so always display it");
						return adData;
					}
					else
					{
						var username:String = "home_" + shellApi.profileManager.active.login;
						var lso:SharedObject = SharedObject.getLocal(username, "/");
						lso.objectEncoding = ObjectEncoding.AMF0;
						var vector:Vector.<String>;
						if (lso.data.campaigns == null)
							vector = new Vector.<String>();
						else
							vector = lso.data.campaigns;
						// if ad not found in list
						if (vector.indexOf(adName) == -1)
						{
							trace("home popup not found in lso, so display it");
							vector.push(adName);
							// add to list and save
							lso.data.campaigns = vector;
							lso.flush();
							return adData;
						}
						trace("home popup found in lso, so don't display it");
					}
				}
			}
			return null;
		}

		/**
		 * Get ad data for theater poster
		 * @return AdData
		 */
		public function getTheaterPosterData():AdData
		{
			return getAdData(_theaterPosterType);
		}
		
		/**
		 * Get campaign XML
		 */
		public function getCampaignXML(campaignName:String, pullFromServer:Boolean):void
		{
			// get campaign name for converted quest without Interior
			campaignName = AdUtils.convertNameToQuest(campaignName, AdUtils.QUEST_SUFFIX, true);
			var path:String = "data/" + AdvertisingConstants.AD_PATH_KEYWORD + "/" + campaignName + "/" + AdvertisingConstants.CAMPAIGN_FILE;
			
			// set up full URL if from CMS and pulling from server
			if ((AppConfig.adsFromCMS) && (pullFromServer))
				path = "https://" + super.shellApi.siteProxy.fileHost + "/game/" + path;
			
			var request:URLRequest = new URLRequest(path);
			var urlLoader:URLLoader = new URLLoader();
			
			// add listeners
			urlLoader.addEventListener(Event.COMPLETE, Command.create(gotCampaignXML, campaignName) );
			urlLoader.addEventListener(IOErrorEvent.IO_ERROR, Command.create(gotCampaignXMLError, campaignName) );
			
			// get data
			request.method = URLRequestMethod.GET;
			urlLoader.load(request);
			
			// this prevented new campaign.xml files from overwriting local versions of the same
			//shellApi.loadFile( path, Command.create(gotCampaignXML, campaignName) );
		}
		
		/**
		 * Got campaign XML
		 */
		private function gotCampaignXML(e:Event, campaignName:String):void
		{
			// note: xml file will fail to load if XML is malformed
			if ((e.target.data == null) || (e.target.data == ""))
			{
				trace("AdManager: gotCampaignXML failed. Check for malformed xml or missing file: " + campaignName);
			}
			else
			{
				trace("AdManager: gotCampaignXML: " + campaignName);
				var xml:XML = XML(e.target.data);
				var campaignData:CampaignData = new CampaignData(xml);
				addActiveCampaign(campaignData);
			}
		}
		
		private function gotCampaignXMLError(e:Event, campaignName:String):void
		{
			trace("AdManager: gotCampaignXML: Error: " + campaignName);
		}
		
		// UTILITY FUNCTIONS //////////////////////////////////////////////////////////////////////////
		
		/**
		 * Convert scene type from scene type, checking if swapping billboards with main street ads
		 * Called from SceneParser
		 * @param SceneType
		 * @return SceneType
		 */
		public function convertSceneType(sceneType:String):String
		{
			// // if allow swapping of billboards, then force to main street ad
			//if ((_allowSwapBillboard) && (sceneType == SceneType.BILLBOARD))
			if (sceneType == SceneType.BILLBOARD)
				sceneType = SceneType.MAINSTREET;
			return sceneType;
		}
		
		/**
		 * Returns whether the island has a billboard
		 */
		/*
		public function hasBillboard():Boolean
		{
			// if swapping billboards with main street ads, then no billboards
			if (_allowSwapBillboard)
				return false;
			
			// if island has billboard off main, then return true
			if (getAdData(_billboardType, true))
			{
				trace("AdManager: Island has " + _billboardType);
				return true;
			}
			else
			{
				return false;
			}
		}
		*/
		
		/**
		 * Returns whether the island has a main street billboard
		 */
		/*
		public function hasMainStreetBillboard():Boolean
		{
			// if island has billboard on main, then return true
			if (getAdData(_billboardType, false))
			{
				trace("AdManager: Island has main street " + _billboardType);
				return true;
			}
			else
			{
				return false;
			}
		}
		*/
		
		/**
		 * Returns whether the island has a main street ad or main street wrapper
		 */
		public function hasMainStreetAd():Boolean
		{
			// init to false
			var vHasMainStreetAd:Boolean = false;
			
			// if island has main street ad on main street, then set to true
			if (getAdData(_mainStreetType, false))
			{
				vHasMainStreetAd = true;
			}
			else if (getAdData(AdCampaignType.WRAPPER, false))
			{
				// if main street wrapper, then set to true
				vHasMainStreetAd = true;
			}
			if (vHasMainStreetAd)
				trace("AdManager: Island has main street ad or wrapper");
			return vHasMainStreetAd;
		}
		
		/**
		 * Retrieves campaign item ids and adds them to profile
		 * @param itemsArray Array of card IDs
		 * @param activeCampaigns Array of active campaigns in CMS
		 * 
		 */
		public function AddCampaignCardsToProfile( itemsArray:Array, activeCampaigns:Array ):void
		{
			// get profile manager
			var profileManager:ProfileManager = super.shellApi.getManager( ProfileManager ) as ProfileManager;
			
			// create array is no custom card group
			if (profileManager.active.items[CardGroup.CUSTOM] == null)
				profileManager.active.items[CardGroup.CUSTOM] = new Array();

			// for each card ID in array
			for each ( var itemId:Object in itemsArray )
			{
				var item:String = String(itemId);
				// check items against active campaigns in CMS (pulled from LSO)
				// current campaigns is null when guest
				// if null or card ID is found in list of active campaigns
				if ((activeCampaigns == null) || (activeCampaigns.indexOf(item) != -1))
				{
					// convert to number
					var itemNum:Number = Number(itemId);
					// check to see if item is stored in profile, if not then add it and set it to "new"
					if ( profileManager.active.items[CardGroup.CUSTOM].indexOf(itemNum) == -1 )
					{
						profileManager.inventoryType = CardGroup.CUSTOM;
						profileManager.active.newInventoryCard = true;
						profileManager.active.items[CardGroup.CUSTOM].push(itemNum);
					}
				}
			}
		}
		
		/**
		 * Send tracking pixels (called by Inventory.as in core) 
		 * @param trackingPixelURL
		 */
		/*
		public function sendTrackingPixels(trackingPixelURL:String):void
		{
			AdUtils.sendTrackingPixels(shellApi, trackingPixelURL);
		}
		*/
		
		// SOUND FUNCTIONS //////////////////////////////////////////////////////////////
		
		/**
		 * Play campaign music
		 */
		public function playCampaignMusic(musicFile:String):void
		{
			var scene:Scene = shellApi.sceneManager.currentScene;
			if (_audioSystem == null)
				_audioSystem = AudioSystem(scene.getSystem(AudioSystem));
			_audioSystem.unMuteSounds();
			_musicWrapperCurVolume = _audioSystem.getVolume("music");
			_ambientCurVolume = _audioSystem.getVolume("ambient");
			_audioSystem.setVolume(0.001, "music");
			_audioSystem.setVolume(0, "ambient");
			_musicWrapper = AudioUtils.play(scene, SoundManager.MUSIC_PATH + musicFile, 1, true, null, "campaignMusic", _musicWrapperCurVolume);
		}
		
		/**
		 * Stop campaign music
		 */
		public function stopCampaignMusic(playVideo:Boolean = false):void
		{
			if (_audioSystem != null)
			{
				// stop music and restore previous audio
				AudioUtils.stop(shellApi.sceneManager.currentScene, null, "campaignMusic");
				_audioSystem.setVolume(_musicWrapperCurVolume, "music");
				_audioSystem.setVolume(_ambientCurVolume, "ambient");
				if (playVideo)
					_audioSystem.muteSounds();
				_audioSystem = null;
			}
		}
				
		// STATIC FUNCTIONS ///////////////////////////////////////////////////////////
		
		/**
		 * Visit sponsor site based on campaign name (used for photobooth)
		 * @param shellApi
		 * @param campaignName
		 * @param useBumper Use bumper dialog to tell user we are leaving app
		 */
		public function visitSponsor(campaignName:String, useBumper:Boolean = false):void
		{
			// first get ad data for campaign type on main street
			var adData:AdData = getAdDataByCampaign(campaignName);
			// if has ad data and click URL
			if ((adData) && (adData.clickURL))
			{
				// if using bumper dialog, then display it
				if (useBumper)
				{
					visitSponsorSite(shellApi, adData.campaign_name, Command.create(triggerSponsorSite, adData));
				}
				else
				{
					// if no bumper, then go to sponsor site immediately
					triggerSponsorSite(adData);
				}
			}
		}
		
		/**
		 * trigger sponsor site (used for photobooth)
		 * @param shellApi
		 * @param adData
		 */
		private function triggerSponsorSite(adData:AdData):void
		{
			// track using campaign type as choice
			track(adData.campaign_name, AdTrackingConstants.TRACKING_CLICK_TO_SPONSOR, "Photobooth");
			// open sponsor url
			AdUtils.openSponsorURL(shellApi, adData.clickURL, adData.campaign_name, "Photobooth", "");
		}
		
		/**
		 * Go to sponsor site after optional delay
		 * @param shellApi
		 * @param triggerSponsor function to call after delay
		 * @param cardItem
		 * @param cardAction
		 */
		static public function visitSponsorSite(shellApi:ShellApi, campaignName:String, triggerSponsor:Function, cardItem:CardItem = null, cardAction:CardAction = null, clickURL:String=null):void
		{
			// default to no bumper
			var bumper:Boolean = false;
			
			// allow for web now
			//if (AppConfig.mobile)
			{
				// don't user bumper if pop url for card
				if ((cardAction) && (String(cardAction.params.byId("urlId")).substr(0,6) == "pop://"))
					bumper = false;
				else
					bumper = true;
			}
			if(clickURL != null) 
			{
				if (clickURL.substr(0,6) == "pop://")
				{
					bumper = false;
				}
			}
			// if bumper then display confirmation popup with delay
			if (bumper)
			{
				// get current scene
				var scene:Scene = shellApi.sceneManager.currentScene;
				
				// if no network then show error message
				if (!shellApi.networkAvailable())
				{
					var sceneUIGroup:SceneUIGroup = scene.groupManager.getGroupById(SceneUIGroup.GROUP_ID) as SceneUIGroup;
					sceneUIGroup.askForConfirmation(SceneUIGroup.CONNECT_TO_INTERNET, sceneUIGroup.removeConfirm, sceneUIGroup.removeConfirm);
					return;
				}
				
				// load bumper popup (only load if not already loaded)
				if (scene.getGroupById("LeavingPopBumper") == null)
				{
					var popupGroup:Group = scene.addChildGroup(new LeavingPopBumper(triggerSponsor, campaignName, cardItem, cardAction));
					popupGroup['init'](scene.overlayContainer);
				}
			}
			else
			{
				// if no bumper
				// call function immediately
				if (cardItem)
					triggerSponsor(cardItem, cardAction);
				else
					triggerSponsor();
			}
		}
		
		// GETTER SETTER FUNCTIONS /////////////////////////////////////////////////////
		
		public function get isInterior():Boolean { return _isInteriorScene; }
		public function get wasInterior():Boolean { return _wasInteriorScene; }
		public function get adTypes():Array { return _adTypes; }
		public function get campaignStreetType():String { return _campaignStreetType; }
		public function get mainStreetType():String { return _mainStreetType; }
		//public function get billboardType():String { return _billboardType; }
		public function get vendorCartType():String { return _vendorCartType; }
		public function get photoBoothType():String { return _photoBoothType; }
		public function get miniGameType():String { return _miniGameType; }
		public function get blimpType():String { return _blimpType; }
		public function get scavengerItemType():String { return _scavengerItemType; }
		public function get offMain():Boolean { return _offMain; }
		public function get defaultOffMain():Boolean { return _defaultOffMain; }
		public function get swappable():Boolean { return _swappable; }
		//public function get forceMainStreetAdInBillboardScene():Boolean { return _allowSwapBillboard;}
		public function get allowRemainingAds():Array { return _allowRemainingAds; }
		public function get adsLoaded():Array { return _adsLoaded; }
		public function get hasAdBuilding():Boolean { return _hasAdBuilding; }
		public function get carouselDelay():int { return _carouselDelay; }
		public function get minibillboardDelay():int { return _minibillboardDelay; }
		public function set returnToInterior(value:Boolean):void {_returnToInterior = value; }
		public function get returnToInterior():Boolean { return _returnToInterior; }
		public function set wonQuest(value:Boolean):void {_wonQuest = value; }
		public function get wonQuest():Boolean { return _wonQuest; }
		public function get bumperDelay():Number { return _bumperDelay; }
		public function get brandingDelay():Number { return _brandingDelay; }
		public function get questSuffix():String { return _questSuffix;}
		public function set questSuffix(suffix:String):void { _questSuffix = suffix;}
		public function get interiorSuffix():String { return _interiorSuffix;}
		public function set interiorSuffix(suffix:String):void { _interiorSuffix = suffix;}
		public function get interiorAd():AdData { return _interiorAd;}
		public function set interiorAd(ad:AdData):void { _interiorAd = ad;}
		public function get countryCode():String { return _countryCode; }
		
		// for handling active campaigns
		public function addActiveCampaign( campaignData:CampaignData ):void
		{
			var convertedCampaignName:String = AdUtils.convertNameToQuest(campaignData.campaignId);
			_activeCampaigns[convertedCampaignName] = campaignData;
			
			// if web then add to LSO
			if (!AppConfig.mobile)
			{
				var campaigns:SharedObject = AdUtils.campaignsLSO;
				campaigns.data[convertedCampaignName] = AdUtils.convertCampaignDataForLSO(campaignData);
				campaigns.flush();
			}
		}
		
		public function getActiveCampaign( campaignId:String ):CampaignData
		{
			trace("AdManager :: getActiveCampaign - " + campaignId + " coverted to quest format - " + AdUtils.convertNameToQuest(campaignId));
			return _activeCampaigns[AdUtils.convertNameToQuest(campaignId)];
		}
		
		// get custom string from ad settings
		public function getCustomString(num:int):String
		{
			// if 1 - 4
			if ((num > 0) && (num < 5))
				return DataUtils.getString(_adSettings["custom" + num]);
			else
				return "";
		}
		
		// CLASS VARIABLES /////////////////////////////////////////////////////////////
		
		private var _cmsCompleteSignal:Signal = new Signal(); // completion signal for CMS fetching
		private var _adTypes:Array; // supported ad types
		private var _activityTimer: ActivityTimer; // activity timer
		private var _activeCampaigns:Dictionary; // list of active campaigns that have cards
		private var _isInteriorScene:Boolean = false;
		private var _wasInteriorScene:Boolean = false;
		private var _shortIslandMain:Boolean = false; // whether current scene is a short island main street scene
		private var _allowRemainingAds:Array = []; // frequency cap group IDs for campaigns that reach cap on current scene
		private var _adsLoaded:Array = []; // ads already loaded on this scene
		private var _hasAdBuilding:Boolean = false; // whether scene has ad building
		private var _npcFriend:AdNpcFriend; // NPC friend object on scene
		private var _adsReadyCallback:Function; // callback when ads are ready
		private var _totalSceneAds:int; // number of ads to load to wait for
		private var _sceneAdCounter:int; // to count ads as they load
		private var _carouselDelay:int = 10; // home scene billboard carousel delay
		private var _minibillboardDelay:int = 10; // home scene billboard carousel delay
		private var _bumperDelay:Number = 3; // mobile bumper delay when leaving app
		private var _brandingDelay:Number = 15; // branding timer delay
		private var _returnToInterior:Boolean = false;
		private var _wonQuest:Boolean = false;
		private var _questSuffix:String = ""; // suffix to be added to ad interior scenes for multi-quests
		private var _interiorSuffix:String = "";
		private var _countryCode:String = "US"; // country code - defaults to US
		
		// music variables
		private var _audioSystem:AudioSystem;
		private var _musicWrapperCurVolume:Number;
		private var _ambientCurVolume:Number;
		private var _musicWrapper:AudioWrapper; // wrapper for campaign music

		// When entering ad quest interior, keep track of scene you entered from so we can return when exiting
		protected var _entranceScene:String;
		protected var _entranceSceneX:int;
		protected var _entranceSceneY:int;
		protected var _entranceSceneDirection:String;
		protected var _interiorAd:AdData;
		
		protected var _offMain:Boolean = true; // whether current scene is on/off main
		protected var _sceneType:String; // scene type of current scene
		protected var _swappable:Boolean = false; // whether current scene is swappable for billboards/main street ads
		protected var _defaultOffMain:Boolean = true; // default offMain for current scene
		//protected var _allowSwapBillboard:Boolean = true; // whether ad settings allow the swapping of billboards
		protected var _as2Island:String; // current AS2 island name (used because LSO uses AS2 island names)
		protected var _lastIsland:String; // previous island
		protected var _nextIsland:String; // previous island
		protected var _cmsCampaigns:Vector.<AdData>; // list of AdData objects (across islands) created from CMS data during session
		protected var _cappedCampaigns:Vector.<AdData>; // list of AdData objects (across islands) of capped campaigns
		protected var _campaignStreetType:String = ""; // street type for current scene (used only for billboards and main street ads)
		protected var _adSettings:AdSettingsData; // ad settings data object created from xml
		
		// default ad types (overriden by AdManagers)
		protected var _mainStreetType:String = AdCampaignType.MAIN_STREET;
		//protected var _billboardType:String = AdCampaignType.BILLBOARD;
		protected var _autocardType:String = AdCampaignType.AUTOCARD;
		protected var _npcFriendType:String = AdCampaignType.NPC_FRIEND;
		protected var _vendorCartType:String = AdCampaignType.VENDOR_CART;
		protected var _photoBoothType:String = AdCampaignType.WEB_PHOTO_BOOTH;
		protected var _miniGameType:String	= AdCampaignType.WEB_MINI_GAME;
		protected var _carouselType:String = AdCampaignType.WEB_CAROUSEL;
		protected var _minibillboardType:String = AdCampaignType.STANDARD_DISPLAYBILLBOARD;
		protected var _blimpType:String = AdCampaignType.WEB_BLIMP;
		protected var _theaterPosterType:String = AdCampaignType.WEB_THEATER_POSTER;
		protected var _scavengerItemType:String = AdCampaignType.WEB_SCAVENGER_ITEM;
		protected var _homePopupType:String = AdCampaignType.WEB_HOME_POPUP;
		protected var _theater:String = AdCampaignType.THEATER;
	}
}