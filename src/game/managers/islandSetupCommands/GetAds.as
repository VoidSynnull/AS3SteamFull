package game.managers.islandSetupCommands
{
	import com.poptropica.AppConfig;
	
	import engine.ShellApi;
	import engine.command.CommandStep;
	
	import game.data.ads.AdCampaignType;
	import game.data.ads.AdvertisingConstants;
	import game.managers.ads.AdManager;
	import game.util.ProxyUtils;
	import game.utils.AdUtils;
	
	/**
	 * GetAds
	 * 
	 * If ads are active this command will check if any exist on a new island.  If so it will load the required content.
	 * (might want the check and load to happen in separate commands.)
	 */
	
	public class GetAds extends CommandStep
	{
		/**
		 * Start command to get ad content for island
		 * @param shellApi
		 * @param nextIsland - island being opened
		 * @param newIsland - flag determining if new, essentailly if the next island is not equal to current island
		 */
		public function GetAds(shellApi:ShellApi, nextIsland:String, newIsland:Boolean = true)
		{
			super();
			
			_shellApi = shellApi;
			_nextIsland = ProxyUtils.convertIslandToAS2Format(nextIsland);	// strip off _as3 and make first letter capital
			_newIsland = newIsland;
		}
		
		/**
		 * Execute step 
		 */
		override public function execute():void
		{
			// if ads are active and new island
			// for ad crunch we want to refresh ads more often.
			
			if ((AppConfig.adsActive) && (_newIsland || _everyScene))
			{
				var adManager:AdManager = AdManager(_shellApi.adManager);
				var isMap:Boolean = false;
				var adTypes:Array;
				
				// if map island
				if (_nextIsland == "Map")
				{
					isMap = true;
					// if mobile, set adTypes to array of mobile map ads
					if (AppConfig.mobile)
					{
						adTypes = AdvertisingConstants.MAP_ADS_LIST.slice();
						// add blimp
						adTypes.push(AdCampaignType.WEB_BLIMP);
					}
					else
					{
						// if web then set to map ad driver array
						adTypes = AdvertisingConstants.MAP_ADS_LIST.slice();
						// add blimp
						adTypes.push(AdCampaignType.WEB_BLIMP);
					}
					adTypes.push(AdCampaignType.APP_OF_THE_DAY);
				}
				
				// if entering an ad quest scene, remember current scene so AdManager knows what scene to return to
				if ((_shellApi.island) && (_nextIsland == AdvertisingConstants.AD_ISLAND) && _newIsland)
				{
					// TODO :: Should this get saved to local memeory? - bard
					adManager.saveSceneForEntrance();
				}
				
				// don't update if going to a non legitimate island or coming back from an ad
				if ((AdUtils.isRealIsland(_nextIsland)) && !adManager.isInterior || (isMap))
				{
					// get campaigns for new island
					// if adTypes is null, then adManager will use default types
					adManager.removeAdData(_nextIsland, adManager.mainStreetType, true);
					adManager.removeAdData(_nextIsland, adManager.mainStreetType, false);
					adManager.getCampaignsForIsland(_nextIsland, adTypes, super.complete);
					return;
				}
			}
			super.complete();
		}
		
		protected var _shellApi:ShellApi;
		protected var _nextIsland:String;
		protected var _newIsland:Boolean;
		protected var _everyScene:Boolean = true;
	}
}