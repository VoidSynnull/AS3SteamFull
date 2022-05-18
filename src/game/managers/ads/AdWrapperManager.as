package game.managers.ads
{
	import flash.external.ExternalInterface;
	import flash.system.Security;
	
	import engine.ShellApi;
	
	import game.data.ads.AdCampaignType;
	import game.data.ads.AdData;
	import game.data.ads.AdTrackingConstants;
	import game.data.ads.PlayerContext;
	import game.data.scene.SceneType;
	import game.util.ProxyUtils;
	import game.utils.AdUtils;
	
	public class AdWrapperManager
	{
		// ad wrapper manager is created for browser only
		public function AdWrapperManager(shellApi:ShellApi)
		{
			_shellApi = shellApi;
			
			if (PLAYWIRE)
				return;
			
			// receive messages from javascript
			if (ExternalInterface.available)
			{
				// RLH: The list of domains didn't work for me
				//Security.allowDomain("poptropica.com", "static.poptropica.com", "dev.poptropica.com", "static.dev.poptropica.com");
				Security.allowDomain("*");
				try{
					trace("AdWrapperManager: add callbacks");
					ExternalInterface.addCallback("clickLeftWrapper", clickLeftWrapper);
					ExternalInterface.addCallback("clickRightWrapper", clickRightWrapper);
				} catch (error:SecurityError) {
					trace("AdWrapperManager: A SecurityError occurred: " + error.message);
				} catch (error:Error) {
					trace("AdWrapperManager: An Error occurred: " + error.message);
				}
			}
		}
		
		/**
		 * Remove wrapper
		 */
		public function clearWrapper():void
		{
			if (PLAYWIRE)
				return;
			
			trace("AdWrapperManager: clear wrapper");
			_lastWrapper = "";
			_wrapperData = null;
			
			// tell Javascript to clear wrapper
			if (ExternalInterface.available)
				ExternalInterface.call("clearWrapper");
		}
		
		/**
		 * Expire main street wrapper
		 */
		public function expireMainStreetWrapper():void
		{
			if (PLAYWIRE)
				return;

			trace("AdWrapperManager: expire main street wrapper");
			// get main street wrapper
			var wrapperData:AdData = _shellApi.adManager.getAdData(AdCampaignType.WRAPPER, false);
			if (wrapperData)
				_expired = wrapperData.campaign_name;
			clearWrapper();
		}
		
		/**
		 * Determine wrapper to be loaded for scene
		 * @param shellApi
		 * @param forceOffMain (used when called from Lands scene)
		 * @param sceneType
		 * @param island
		 */
		public function doWrapper(forceOffMain:Boolean, sceneType:String, island:String):void
		{
			var adManager:AdManager = AdManager(_shellApi.adManager);
			
			// set offmain to true as default
			var offMain:Boolean = true;
			// set wrapper ad data to null
			_wrapperData = null
			// flag to trigger ad inventory tracking
			var needsAdInventoryTracking:Boolean = false;
			
			// if forcing off main wrapper (from lands)
			if (forceOffMain)
			{
				// use default of offMain
				trace("AdWrapperManager: load wrapper for forced off-main street");
			}
			else
			{
				// if not forcing off main, then get off main value from ad manager
				offMain = adManager.offMain;
			}
			
			if (PLAYWIRE)
			{
				// for interior wrappers
				if (sceneType == SceneType.ADINTERIOR)
				{
					offMain = false;
				}
				if (_shellApi.sceneName == "Login")
					return;
				if (ExternalInterface.available)
				{
					var msCampaign:String = "none";
					// if main street
					if (!offMain)
					{
						// get main street ad if any
						var ad:AdData = adManager.getAdData(AdCampaignType.MAIN_STREET, false, false, island);
						if (ad != null)
						{
							msCampaign = ad.campaign_name;
						}
					}
					// suppress forced wrappers if map
					if (_shellApi.sceneName == "Map")
					{
						msCampaign = "none";
					}
					ExternalInterface.call('dbug', "forced campaign: " + msCampaign);
					ExternalInterface.call("refreshWrapper", msCampaign);
				}
				return;
			}
			
			// check scene type
			switch (sceneType)
			{
				case SceneType.CUTSCENE:
					trace("AdWrapperManager: Don't show wrapper on cut scene");
					break;
				
				case SceneType.NOWRAPPER:
					trace("AdWrapperManager: Force no wrapper");
					break;
				
				case SceneType.BILLBOARD:
					trace("AdWrapperManager: Don't load wrapper on billboard scene.");
					// if default scene is main street scene, then send ad inventory tracking call
					// this happens when forcing billboard onto main street scene
					if (!adManager.defaultOffMain)
						needsAdInventoryTracking = true;
					break;
				
				case SceneType.ADINTERIOR:
					trace("AdWrapperManager: Don't load wrapper in ad interior.");
					break;
				
				default: // all other scene types
					trace("AdWrapperManager: Checking for wrapper for " + sceneType);
					// need for tracking
					var wrapperType:String;
					
					// if off main
					if (offMain)
					{
						needsAdInventoryTracking = true;
						wrapperType = "offMain";
					}
					else 
					{
						// if on main
						wrapperType = "onMain";
						// if default scene is not main street scene, then suppress ad inventory tracking
						// this happens when forcing main street ad onto billboard scene
						// if default scene is main street, then send inventory tracking call
						if (!adManager.defaultOffMain)
							needsAdInventoryTracking = true;
					}
					
					// get wrapper data
					_wrapperData = adManager.getAdData(AdCampaignType.WRAPPER, offMain, true);
					
					// if data found
					if(_wrapperData != null)
					{
						// check if main street wrapper has expired
						if (_wrapperData.campaign_name == _expired)
						{
							trace("AdWrapperManager: main street wrapper has expired, don't display it");
							_wrapperData = null;
						}
						// check if off main wrapper is branded and expired
						else if ((offMain) && (_wrapperData.campaign_name.toLowerCase().indexOf("branded") != -1) && (AdUtils.checkBranding(_shellApi.sceneManager.currentScene, _wrapperData.campaign_name)))
						{
							trace("AdWrapperManager: branded off main wrapper has expired, don't display it");
							_wrapperData = null;
						}
						else
						{
							trace("AdWrapperManager: load wrapper: offMain: " + offMain);
							sendWrapper(offMain, wrapperType);
						}
					}
					break;
			}
			
			// if triggering ad inventory event
			if (needsAdInventoryTracking)
			{
				// set choice value for event call
				var wrapperChoice:String;
				if (adManager.defaultOffMain)
					wrapperChoice = "Wrapper Off Main";
				else
					wrapperChoice = "Wrapper On Main";
				// send call
				adManager.track(AdTrackingConstants.AD_INVENTORY, AdTrackingConstants.TRACKING_AD_SPOT_PRESENTED, wrapperChoice);
			}
			
			// if no wrapper data then clear
			if (_wrapperData == null)
			{
				// clear wrapper if no wrapper to show
				trace("AdWrapperManager: No wrapper to show");
				_lastWrapper = "";
				
				// tell Javascript to clear wrapper
				if (ExternalInterface.available)
					ExternalInterface.call("clearWrapper");
			}
		}
		
		/**
		 * Notify page to load wrapper into html divs
		 * @param shellApi
		 * @param offMain
		 * @param wrapperType
		 */
		private function sendWrapper(offMain:Boolean, wrapperType:String):void
		{
			// if no data for some reason, then abort
			if (_wrapperData == null)
			{
				trace("AdWrapperManager: error: no data to send to wrapper!");
			}
			else
			{
				// if have data
				trace("AdWrapperManager: wrapperLoaded: campaign: " + _wrapperData.campaign_name + ", left: " + _wrapperData.leftWrapper + ", right: " + _wrapperData.rightWrapper + ", offMain: " + offMain);
				// send tracking call
				AdManager(_shellApi.adManager).track(_wrapperData.campaign_name, AdTrackingConstants.TRACKING_IMPRESSION, "Wrapper", wrapperType);
				// trigger tracking pixel impression (now handled by tracking call)
				// AdUtils.sendTrackingPixels(_shellApi, _wrapperData.campaign_name, _wrapperData.impressionURL);
				// if new wrapper from last, then send wrapper to page
				if (_wrapperData.campaign_name != _lastWrapper)
				{
					trace("AdWrapperManager: wrapper displayed on page");
					// remember wrapper
					_lastWrapper = _wrapperData.campaign_name;
					// notify page to load wrapper
					if (ExternalInterface.available)
					{
						// convert age to grade
						var age:int = _shellApi.profileManager.active.age;
						if (age == 0)
							age = PlayerContext.DEFAULT_AGE;
						var grade:String = String(age - 5);
						
						// get gender
						var gender:String = ProxyUtils.convertGenderToServerFormat(_shellApi.profileManager.active.gender);
						
						// tell Javascript to show wrapper
						if ((_wrapperData.campaign_name) && (_wrapperData.campaign_name != ""))
							ExternalInterface.call("showWrapper", _wrapperData.campaign_name, _wrapperData.clickURL, _wrapperData.leftWrapper, _wrapperData.rightWrapper);
					}
				}
			}
		}
		
		/**
		 * When left wrapper clicked (called by Javascript)
		 */
		public function clickLeftWrapper():void
		{
			if (_wrapperData == null)
			{
				trace("AdWrapperManager: click left wrapper: no data");
			}
			else
			{
				trace("AdWrapperManager: click left wrapper success");
				_shellApi.adManager.track(_wrapperData.campaign_name, AdTrackingConstants.TRACKING_CLICK_TO_SPONSOR, "Wrapper", "Left");
				var urlArr:Array = AdUtils.parseURLs(_wrapperData.clickURL);
				// open first URL in array
				AdUtils.openSponsorURL(_shellApi, urlArr[0], _wrapperData.campaign_name, "Wrapper", "Left");
				checkBrandedWrapper();
			}
		}
		
		/**
		 * When right wrapper clicked (called by Javascript)
		 */
		public function clickRightWrapper():void
		{
			if (_wrapperData == null)
			{
				trace("AdWrapperManager: click right wrapper: no data");
			}
			else
			{
				trace("AdWrapperManager: click right wrapper success");
				_shellApi.adManager.track(_wrapperData.campaign_name, AdTrackingConstants.TRACKING_CLICK_TO_SPONSOR, "Wrapper", "Right");
				var urlArr:Array = AdUtils.parseURLs(_wrapperData.clickURL);
				// default to second position in array
				var index:int = 1;
				// if array has only one item, then set index to first position
				if (urlArr.length == 1)
					index = 0;
				AdUtils.openSponsorURL(_shellApi, urlArr[index], _wrapperData.campaign_name, "Wrapper", "Right");
				checkBrandedWrapper();
			}
		}
		
		/**
		 * Check for branded wrapper off main and start branding timer 
		 * Wrapper campaign MUST have "Branded" in its name
		 */
		private function checkBrandedWrapper():void
		{
			if ((_wrapperData.campaign_name.toLowerCase().indexOf("branded") != -1) && (_wrapperData.offMain))
				AdUtils.interactWithCampaign(_shellApi.sceneManager.currentScene, _wrapperData.campaign_name, true)
		}
		
		private const PLAYWIRE:Boolean = true;
		private var _shellApi:ShellApi;
		private var _lastWrapper:String = "";
		private var _wrapperData:AdData;
		private var _expired:String; // expired main street wrapper
	}
}