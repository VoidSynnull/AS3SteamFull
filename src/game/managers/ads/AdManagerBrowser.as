package game.managers.ads
{
	import engine.group.Group;
	
	import game.data.ads.AdCampaignType;
	import game.data.ads.AdData;
	import game.data.ads.AdSettingsData;
	import game.data.ads.AdvertisingConstants;
	import game.data.scene.SceneType;
	import game.managers.ads.AdManager;
	import game.proxy.browser.AdProxyUtils;
	import game.util.PlatformUtils;
	
	public class AdManagerBrowser extends AdManager
	{
		// ad manager is created only if ads are active
		public function AdManagerBrowser()
		{
		}
		
		// OVERRIDEN FUNCTIONS/////////////////////////////////////////////////////////////////////
		
		/**
		 * Initialize ad manager for browser
		 * @param adTypes ad types that are suppored on browser
		 */
		override public function init(adTypes:Array):void
		{
			super.init(adTypes);

			// create empty adSettingsData object (only used on browser)
			_adSettings = new AdSettingsData();

			// init wrapper manager for wrapper ads
			wrapperManager = new AdWrapperManager(shellApi);

			// get any campaigns from LSO if not desktop
			// moved to BrowserStepGetFirstScene
			//getCampaignsFromLSO();
		}
		
		public function getCampaignsFromLSO():void
		{
			// get any campaigns from LSO if not desktop
			if (PlatformUtils.inBrowser)
			{
				AdProxyUtils.getCampaignsFromLSO(AdManager(this), super.adTypes);
			}
		}
		
		/**	
		 * Triggered on every scene load, determines what ad functionality should be added to scene.  
		 * Handler for SceneManager's sceneLoaded signal
		 * @param scene
		 */
		override protected function handleSceneLoaded(scene:Group):void
		{
			super.handleSceneLoaded(scene);
			
			// manage wrapper ads except on lands which loads the wrappers directly
			// except for ad scene on lands which is a main street scene (rest of lands is short main)
			if ((shellApi.island != "lands") || (_sceneType == SceneType.MAINSTREET) || (_sceneType == SceneType.ADINTERIOR))
			{
				if(shellApi.island != "photoBoothIsland")
					handleWrapper();
			}
		}
		
		/**
		 * checks for any active map ad drivers and return array of campaign names (called from Map)
		 * @param init
		 * @return array
		 */
		public function getMapAdDrivers():Array
		{
			var count:int = 0;
			var arr:Array = [];
			// for all three map ad types
			for each (var type:String in AdvertisingConstants.MAP_ADS_LIST)
			{
				count++;
				// get ad data for mobile map ad on current scene (Map in this case)
				var adDriver:AdData = getAdData(type, false);
				// if found, then add to array
				if (adDriver)
				{
					arr.push(adDriver.campaign_name);
					trace("AdManagerBrowser :: Map Ad Driver: slot: " + count + ", campaign name: " + adDriver.campaign_name);
				}
			}
			return arr;
		}

		// WRAPPER FUNCTIONS ///////////////////////////////////////////////////////////
		
		/**
		 * Handle wrapper for current scene 
		 * @param forceOffMain boolean indicating whether to force off main wrappers (used in Lands)
		 */
		public function handleWrapper(forceOffMain:Boolean = false):void
		{
			wrapperManager.doWrapper(forceOffMain, _sceneType, _as2Island);
		}
		
		/**
		 * Get wrapper campaign name
		 * @return campaign name string
		 */
		public function getWrapperCampaign():String
		{
			// get off main wrapper data
			var wrapperData:AdData = getAdData(AdCampaignType.WRAPPER, true);
			// if no data, return null
			if (wrapperData == null)
			{
				trace("AdManager: getWrapperCampaign: null");
				return null;
			}
			else
			{
				// else return campaign name
				trace("AdManager: getWrapperCampaign: " + wrapperData.campaign_name);
				return (wrapperData.campaign_name);
			}
		}
		
		/**
		 * Get wrapper click URL
		 * @return campaign click URL string
		 */
		public function getWrapperClickURL():String
		{
			// get off main wrapper data
			var wrapperData:AdData = getAdData(AdCampaignType.WRAPPER, true);
			// if no data, return null
			if (wrapperData == null)
			{
				return null;
			}
			else
			{
				// else return campaign click URL
				return (wrapperData.clickURL);
			}
		}
		
		/**
		 * Get wrapper tracking pixel impression URL
		 * @return tracking pixel impression URL string
		 */
		public function getWrapperImpressionURL():String
		{
			// get off main wrapper data
			var wrapperData:AdData = getAdData(AdCampaignType.WRAPPER, true);
			// if no data, return null
			if (wrapperData == null)
			{
				return null;
			}
			else
			{
				// else return campaign impression URL
				return (wrapperData.impressionURL);
			}
		}
		
		public var wrapperManager:AdWrapperManager;
	}
}