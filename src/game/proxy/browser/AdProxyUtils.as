package game.proxy.browser 
{
	import com.poptropica.AppConfig;
	
	import flash.net.ObjectEncoding;
	import flash.net.SharedObject;
	
	import engine.ShellApi;
	import engine.components.Spatial;
	
	import game.data.ads.AdCampaignType;
	import game.data.ads.AdData;
	import game.data.ads.AdParser;
	import game.data.ads.AdvertisingConstants;
	import game.data.ads.LsoData;
	import game.managers.ads.AdManager;
	import game.util.ClassUtils;
	import game.util.DataUtils;
	import game.utils.AdUtils;
	
	/**
	 * PopSiteProxy provides Poptropica specific communication services and LSO functions
	 * These are all static functions
	 * @author Rich Martin
	 */	
	public class AdProxyUtils
	{
		public function AdProxyUtils() 
		{
		}
		
		/**
		 * Get campaign data local shared object 
		 * @return LSO
		 */
		static public function getCampaignDataLSO():SharedObject
		{
			var lso:SharedObject = SharedObject.getLocal("campaignData", "/");
			lso.objectEncoding = ObjectEncoding.AMF0;
			return lso;
		}
		
		/**
		 * Get campaigns from local shared object 
		 * @param adManager
		 * @param adTypes
		 */
		static public function getCampaignsFromLSO(adManager:AdManager, adTypes:Array):void
		{
			// create empty list of new islands
			var newIslands:Array = [];
			
			// get AS2 campaign data local shared object
			var lso:SharedObject = getCampaignDataLSO();
//			adManager.shellApi.logWWW("AdProxyUtils::getCampaignsFromLSO()", lso);

			if (! lso.data.hasOwnProperty('campaigns')) {
				adManager.shellApi.logWWW("no campaign data found");
				return;
			}
			// get campaigns object
			var campaigns:Object = lso.data.campaigns;
			
			// return if no campaign data
			if (!campaigns) {
				adManager.shellApi.logWWW("no campaign data found");
				return;
			}
			
//			adManager.shellApi.logWWW("AdProxyUtils :: getCampaignsFromLSO", campaigns);
			// for each campaign object
			for each (var o:Object in campaigns)
			{
				// capped campaign records don't have islands
				// only process supported types for ad manager browser or is interior photo booth
				if ((o.island != null) && ((adTypes.indexOf(o.type) != -1) || (o.type == AdCampaignType.PHOTO_BOOTH_INTERIOR)))
				{
					// campaigns with frequency caps don't get deleted so skip them
					if (o.campaign.campaign_cap_count == 0)
					{
						// add to new island list if not in list
						if (newIslands.indexOf(o.island) == -1) {
							newIslands.push(o.island);
						}
						if (DataUtils.validString(o.campaign.campaign_name)) {
							// create campaign object from LSO object
							createCampaignFromLSOObject(adManager, o);
						} else {
							adManager.shellApi.logWWW("WARNING: skipping an invalid campaign object");
						}
					}
				}
			}

			// now iterate for campaigns with frequency caps
			for each (o in campaigns)
			{
				// capped campaign records don't have islands
				// only process supported types for ad manager browser
				if ((o.island != null) && (adTypes.indexOf(o.type) != -1))
				{
					var lsoCampaign:Object = o.campaign;
					// if has cap and in new island list
					if ((lsoCampaign.campaign_cap_count != 0) && (newIslands.indexOf(o.island) != -1))
					{
						// if more visits allowed
						if (lsoCampaign.campaign_cap_num_visits < lsoCampaign.campaign_cap_count) {
							if (DataUtils.validString(lsoCampaign.campaign_name)) {
								// create campaign object from LSO object
								createCampaignFromLSOObject(adManager, o);
							} else {
								adManager.shellApi.logWWW("WARNING: skipping an invalid campaign object");
							}
						}
					}
				}
			}
		}
		
		/**
		 * Create campaign from LSO object
		 * @param adManager
		 * @param o campaign object from LSO
		 * @param makeActive Boolean to add campaign to both CMS array and active ads array
		 * @return Object which has flattened properties to be processed by AdParser
		 * 
		 */
		static private function createCampaignFromLSOObject(adManager:AdManager, o:Object, makeActive:Boolean = true, isCustomIsland:Boolean = false):Object
		{
			// create empty object
			var campaignObj:Object = {};
			// set campaign type, island and off-main
			campaignObj.campaign_type = o.type;
			campaignObj.island = o.island;
			// offMain is Boolean but incoming object can be 0 or 1
			campaignObj.offMain = o.offMain;
			// if custom island then force to offmain
			if (isCustomIsland)
				campaignObj.offMain = true;
			// set other campaign properties from campaign object
			var lsoCampaign:Object = o.campaign;
			campaignObj.campaign_name				= lsoCampaign.campaign_name;
			campaignObj.click_through_URL			= lsoCampaign.click_through_URL;
			campaignObj.impression_URL				= lsoCampaign.impression_URL;
			campaignObj.campaign_file1				= lsoCampaign.campaign_file1;
			campaignObj.campaign_file2				= lsoCampaign.campaign_file2;
			campaignObj.campaign_cap_count			= int(getCampaignLSOProperty(lsoCampaign, "campaign_cap_count"));
			campaignObj.campaign_cap_period			= int(getCampaignLSOProperty(lsoCampaign, "campaign_cap_period"));
			campaignObj.campaign_cap_group			= int(getCampaignLSOProperty(lsoCampaign, "campaign_cap_group"));
			campaignObj.campaign_cap_num_visits		= int(getCampaignLSOProperty(lsoCampaign, "campaign_cap_num_visits"));
			campaignObj.campaign_cap_first_visit	= getCampaignLSOProperty(lsoCampaign, "campaign_cap_first_visit");

			// if need to make active
			if (makeActive)
			{
				// add to both campaign arrays after parsing
				adManager.makeAdDataCampaignsActive(AdParser.parseAdObject(campaignObj));
				adManager.shellApi.logWWW("AdProxyUtils :: create campaign from LSO object: " + lsoCampaign.campaign_name + " on island " + o.island + " offMain=" + o.offMain);
			}
			return campaignObj;
		}
		
		/**
		 * get LSO property for campaign
		 * @param o campaign object
		 * @param name suffix to be added to string
		 * @return Number
		 */
		static private function getCampaignLSOProperty(o:Object, name:String):Number
		{
			if (o[name])
				return Number(o[name]);
			else
				return 0;
		}
		
		/**
		 * Save campaign data to lso for AS2 scenes
		 * Only if not already in lso (shouldn't overwrite since we only need one ad type per island)
		 */
		static public function saveCampaignsToLSO(dataArray:Vector.<AdData>):void
		{
			var updateLSO:Boolean = false;
			
			// get campaign data local shared object
			var lso:SharedObject = getCampaignDataLSO();
			
			// if campaign object is missing, then create it
			if (lso.data.campaigns == null)
			{
				lso.data.campaigns = [];
				updateLSO = true;
			}
			var campaigns:Object = lso.data.campaigns;
			
			// if islands data is missing, then create it
			if (lso.data.islands == null)
			{
				lso.data.islands = [];
				updateLSO = true;
			}
			
			// for each adData object in array
			for each(var adData:AdData in dataArray)
			{
				var found:Boolean = false;
				
				// check if not already there for the current island
				for each (var o:Object in campaigns)
				{
					// if name and island matches, then don't need to do anything
					if ((o.campaign.campaign_name == adData.campaign_name) && (o.island == adData.island))
					{
						found = true;
						break;
					}
				}
				
				// if not in LSO
				if (!found)
				{
					trace("AdProxyUtils :: Adding campaign to LSO: " + adData.campaign_name);
					
					// create LSO data object and add to LSO
					var lsoData:LsoData = new LsoData(adData);
					campaigns.push(lsoData);
					updateLSO = true;
					
					// add island if isn't there
					if (lso.data.islands == null)
						lso.data.islands = [];
					if (lso.data.islands[adData.island] == null)
						lso.data.islands[adData.island] = true;
				}
			}
			// if needing to update LSO, then save it
			if (updateLSO)
				lso.flush();
		}
		
		/**
		 * Save campaign data to lso for AS2 scenes and check for frequency cap
		 * @param adData
		 * @param island
		 * @param adManager
		 * @return int indicating number that ad is over its frequency cap (ads that have no cap return -1)
		 */
		static public function saveCampaignToLSO(adData:AdData, island:String, adManager:AdManager):int
		{
			var cappedCampaigns:Array = [];
			var reachedCap:Boolean = false;
			
			// set current visits default to -1
			var currentVisits:int = -1;
			
			// get AS2 campaign data shared object
			var lso:SharedObject = getCampaignDataLSO();
			
			// if campaigns object is not in LSO, then create it
			if (lso.data.campaigns == null)
				lso.data.campaigns = [];
			var lsoCampaigns:Object = lso.data.campaigns;
			
			// check to see if already there for the current island
			// for each campaign object in LSO
			for (var i:int = lsoCampaigns.length-1; i != -1; i--)
			{
				// get campaign object
				var o:Object = lsoCampaigns[i];
				var lsoCampaign:Object = o.campaign;
				
				// if capped campaign, then add to current capped campaigns array
				if (o.type == AdvertisingConstants.CAPPED_TYPE)
					cappedCampaigns.push(lsoCampaign.campaign_name);
				
				// if name and island and offMain matches, then delete it from LSO (new campaign will be added to replace this one)
				if ((lsoCampaign.campaign_name == adData.campaign_name) && (o.island == island) && (o.offMain == adData.offMain))
					lsoCampaigns.splice(i,1);
			}
			
			// if has frequency cap
			if (adData.campaign_cap_count != 0)
			{
				trace("AdProxyUtils: saveCampaignToLSO: frequency cap exists for campaign " + adData.campaign_name + " with cap of " + adData.campaign_cap_count);
				
				// get current visits (might be zero if not initialized)
				currentVisits = adData.campaign_cap_num_visits;
				
				// get time of first visit (needs to be number to store UTC time)
				var firstVisit:Number = adData.campaign_cap_first_visit;
				
				// check matching ads on other islands and other campaign groups to get most recent info to apply to this ad	
				for each (o in lsoCampaigns)
				{
					// if not custom island or capped campaign
					if ((o.island != AdvertisingConstants.AD_ISLAND) && (o.type != AdvertisingConstants.CAPPED_TYPE))
					{
						lsoCampaign = o.campaign;
						// if the campaign names or frequency cap IDs match, then get data for campaign
						if ((lsoCampaign.campaign_name == adData.campaign_name) || ((adData.campaign_cap_group != 0) && (lsoCampaign.campaign_cap_group == adData.campaign_cap_group)))
						{
							if (adData.campaign_cap_group != 0)
								trace("AdProxyUtils: saveCampaignToLSO: found matching frequency cap group ID " + adData.campaign_cap_group + " for campaign " + lsoCampaign.campaign_name);
							
							// first check: does this campaign have a first visit time set?
							if (lsoCampaign.campaign_cap_first_visit != 0)
							{
								// second check: does this campaign have a newer first visit time?
								if ((firstVisit == 0) || (lsoCampaign.campaign_cap_first_visit > firstVisit))
								{
									// if so, copy over first visit time and current counter from this campaign
									currentVisits = lsoCampaign.campaign_cap_num_visits;
									firstVisit = lsoCampaign.campaign_cap_first_visit;
									trace("AdProxyUtils: saveCampaignToLSO: found matching frequency cap campaign " + lsoCampaign.campaign_name + " numVisits: " + currentVisits);
								}
								// third check: since this campaign has a first visit time set, does it match the current time?
								else if (lsoCampaign.campaign_cap_first_visit == firstVisit)
								{
									// fourth check: does this campaign have more visits logged?
									if (lsoCampaign.campaign_cap_num_visits > currentVisits)
									{
										// if so, copy this number of visits
										currentVisits = lsoCampaign.campaign_cap_num_visits;
										trace("AdProxyUtils: saveCampaignToLSO: found matching frequency cap campaign " + lsoCampaign.campaign_name + " numVisits: " + currentVisits);
									}
								}
							}
						}
					}
				}
				// we now have the most up-to-date values for the first visit time and number of visits
				
				// get number of seconds since January 1, 1970 (use UTC)
				var now:Date = new Date();
				var nowUTC:Number = Date.UTC(now.getFullYear(), now.getMonth(), now.getDate(), now.getHours(), now.getMinutes(), now.getSeconds());
				
				// if first visit hasn't been filled in yet
				if (firstVisit == 0)
				{
					firstVisit = nowUTC;
					// if not part of campaign group, then reset current visits to zero
					// with campaign groups, we update currentVisits for the entire group at one time
					if (adData.campaign_cap_group == 0)
						currentVisits = 0;
					trace("AdProxyUtils: saveCampaignToLSO: frequency cap first visit doesn't exist, recording current time for " + adData.campaign_name + " num visits: " + currentVisits);
				}
				else if ( (nowUTC - firstVisit) > (adData.campaign_cap_period * 1000) )
				{
					// if the period had ended and needs to be reset (this isn't likely because we delete those records now)
					firstVisit = nowUTC;
					// if not part of campaign group, then reset current visits to zero
					// with campaign groups, we update currentVisits for the entire group at one time
					if (adData.campaign_cap_group == 0)
						currentVisits = 0;
					trace("AdProxyUtils: saveCampaignToLSO: frequency cap period exceeded; recording current time for " + adData.campaign_name + " num visits: " + currentVisits);
				}
				
				// increment counter and limit to max count
				currentVisits++;
				if (currentVisits > adData.campaign_cap_count)
					currentVisits = adData.campaign_cap_count;
				
				trace("AdProxyUtils: saveCampaignToLSO: frequency cap is now " + currentVisits + " for " + adData.campaign_name);
				
				// apply visit data to this record
				adData.campaign_cap_num_visits = currentVisits;
				adData.campaign_cap_first_visit = firstVisit;

				// update all campaigns in campaign group
				if (adData.campaign_cap_group != 0)
				{
					// for each campaign
					for (i = lsoCampaigns.length - 1; i != -1; i--) 
					{
						// if not custom island
						if (lsoCampaigns[i].island != AdvertisingConstants.AD_ISLAND)
						{
							lsoCampaign = lsoCampaigns[i].campaign;
							// if frequency cap groups match, then update current visits and first visit time
							if (lsoCampaign.campaign_cap_group == adData.campaign_cap_group)
							{
								lsoCampaign.campaign_cap_num_visits = currentVisits;
								lsoCampaign.campaign_cap_first_visit = firstVisit;
								trace("AdProxyUtils: saveCampaignToLSO: frequency cap num visits for campaign " + lsoCampaign.campaign_name + " is now " + currentVisits);
							}
						}
					}
				}
				
				// if reached cap then set flag
				if (currentVisits == adData.campaign_cap_count)
				{
					reachedCap = true;
					trace("AdProxyUtils: saveCampaignToLSO: frequency cap reached for: " + adData.campaign_name);
				}
			}
			
			// add island if isn't there, then add it
			if (lso.data.islands == null)
				lso.data.islands = [];
			if (lso.data.islands[island] == null)
				lso.data.islands[island] = true;
			
			// if reached cap
			if (reachedCap)
			{
				// array of ad types to pull from CMS
				var newAdTypes:Array = [adData.campaign_type];
				
				// process lso for campaign groups and matching ads
				for (i = lsoCampaigns.length - 1; i != -1; i--) 
				{
					var campaignIsland:String = lsoCampaigns[i].island;
					// if not custom island and not capped ad
					if ((campaignIsland != AdvertisingConstants.AD_ISLAND) && (lsoCampaigns[i].type != AdvertisingConstants.CAPPED_TYPE))
					{
						lsoCampaign = lsoCampaigns[i].campaign;
						// if campaign group and campaign groups match then add ad type to list since this expired ad is part of a campaign group
						if ((adData.campaign_cap_group != 0) && (lsoCampaign.campaign_cap_group == adData.campaign_cap_group))
						{
							// get type and add to new types if not in list
							var type:String = lsoCampaigns[i].type;
							if (newAdTypes.indexOf(type) == -1)
								newAdTypes.push(type);
						}
						// if campaign name matches then delete from lso
						if (lsoCampaign.campaign_name == adData.campaign_name)
						{
							trace("AdProxyUtils: saveCampaignToLSO: deleting frequency cap ad: " + adData.campaign_name + " on island: " + campaignIsland);
							lsoCampaigns.splice(i, 1);
						}
					}
				}
				
				// add campaign group to allow remaining ads array so that any subsequent ads will display for this main street scene
				// only need this for main street
				if ((!adManager.offMain) && (adManager.allowRemainingAds.indexOf(adData.campaign_cap_group) == -1))
					adManager.allowRemainingAds.push(adData.campaign_cap_group);

				// create capped campaign in lso and delete any matching campaigns in CMS (ad data for this ad won't be added to lso, only a capped equivalent)
				createCappedCampaign(adData, adManager, lso, cappedCampaigns);

				// request new campaign for next tine, to replace capped ad
				// can't do this on mobile because ad zips are loaded only when going to new islands
				if (!AppConfig.mobile)
				{
					trace("AdProxyUtils: saveCampaignToLSO: pulling new campaigns from CMS to replace frequency capped ads: " + adData.campaign_type);
					adManager.getCampaignFromCMS(island, newAdTypes);
				}
			}
			else
			{
				// if didn't reach cap
				trace("AdProxyUtils: saveCampaignToLSO: adding new campaign to LSO: " + adData.campaign_name);
				
				// create new LSO data object from revised adData
				var lsoData:LsoData = new LsoData(adData);
				
				// add to campaigns array in LSO
				lsoCampaigns.push(lsoData);
			}
			
			// save LSO
			lso.flush();
			
			// return number of impressions over frequency cap
			// -1 is default (means its has no cap)
			// 0 means it just reached its cap
			// any positive number means it has exceeded its cap
			return currentVisits - adData.campaign_cap_count;
		}
		
		/**
		 * Get array of all campaigns that have reached their cap
		 * @return array of IDs of capped campaigns
		 */
		static public function getCappedCampaigns(adManager:AdManager):Array
		{
			// get campaign local data shared object
			var lso:SharedObject = getCampaignDataLSO();
			
			// array for capped campaigns
			var cappedCampaigns:Array = [];
			var fullCappedCampaigns:Array = [];
			
			// get campaigns array from LSO
			var lsoCampaigns:Array = lso.data.campaigns;
			// if campaigns found
			if (lsoCampaigns)
			{
				var now:Date = new Date();
				var nowUTC:Number = Date.UTC(now.getFullYear(), now.getMonth(), now.getDate(), now.getHours(), now.getMinutes(), now.getSeconds());
				
				// check each campaign in LSO
				for (var i:int = lsoCampaigns.length-1; i != -1; i--)
				{
					// if capped campaign
					if (lsoCampaigns[i].type == AdvertisingConstants.CAPPED_TYPE)
					{
						var lsoCampaign:Object = lsoCampaigns[i].campaign;
						// if cap time has elapsed, then remove from LSO
						if (nowUTC - lsoCampaign.campaign_cap_first_visit > lsoCampaign.campaign_cap_period * 1000)
						{
							trace("AdProxyUtils: getCappedCampaigns: deleting frequency capped campaign because timer has ended: " + lsoCampaign.campaign_name);
							lsoCampaigns.splice(i,1);
						}
						else
						{
							// if time hasn't elapsed then keep
							var timeRemaining:Number = -(nowUTC - lsoCampaign.campaign_cap_first_visit - lsoCampaign.campaign_cap_period * 1000)/1000/60/60;
							trace("AdProxyUtils: getCappedCampaigns: keeping frequency cap campaign: " + lsoCampaign.campaign_name + " Hours remaining: " + timeRemaining);
							cappedCampaigns.push(lsoCampaign.campaign_name);
							// get full name
							var ad:AdData = adManager.getAdDataByCampaign(lsoCampaign.campaign_name);
							if (ad != null)
							{
								fullCappedCampaigns.push(ad.cms_name);
							}
						}
					}
				}
				
				// if any existing capped campaigns, then delete any matching original campaigns
				if (cappedCampaigns.length != 0)
				{
					trace("AdProxyUtils: getCappedCampaigns: Current frequency capped campaigns: " + cappedCampaigns);
					
					// delete any original campaigns that are now capped
					for each (var campaignName:String in cappedCampaigns)
					{
						for (i = lsoCampaigns.length-1; i != -1; i--)
						{
							// if not capped
							if (lsoCampaigns[i].type != "capped")
							{
								// if match names
								if (lsoCampaigns[i].campaign.campaign_name == campaignName)
								{
									trace("AdProxyUtils: getCappedCampaigns: deleted frequency cap original campaign from LSO before calling CMS: " + campaignName);
									lsoCampaigns.splice(i, 1);
								}
							}
						}
					}
				}
				
				// now look for new ones that have capped and not been converted
				for (i = lsoCampaigns.length-1; i != -1; i--)
				{
					var o:Object = lsoCampaigns[i];
					// if not custom island or capped campaign
					if ((o.island != AdvertisingConstants.AD_ISLAND) && (o.type != AdvertisingConstants.CAPPED_TYPE))
					{
						lsoCampaign = o.campaign;
						// if valid campaign cap count
						if (lsoCampaign.campaign_cap_count != 0)
						{
							// if num visits greater than or equals cap
							if (lsoCampaign.campaign_cap_num_visits >= lsoCampaign.campaign_cap_count)
							{
								// if not in allowed remaining ads array or is in ads already loaded, then can delete ad and create capped ad
								// we don't want to delete ads as part of a campaign group that haven't yet loaded for the current scene
								// we can delete ads if they have already loaded, even if they are part of the same campaign group
								trace("AdProxyUtils: getCappedCampaigns: ad is expired: " + lsoCampaign.campaign_name + " allowed frequency cap groups: " + adManager.allowRemainingAds + " loaded ads: " + adManager.adsLoaded);
								if ((adManager.allowRemainingAds.indexOf(lsoCampaign.campaign_cap_group) == -1) || (adManager.adsLoaded.indexOf(lsoCampaign.campaign_name) != -1))
								{
									// convert lso campaign into usable data object
									var campaignObj:Object = createCampaignFromLSOObject(adManager, o, false);
									// convert to capped campaign in LSO and delete any matching campaigns in CMS
									var fullName:String = createCappedCampaign(campaignObj, adManager, lso, cappedCampaigns);
									if (fullName != null)
										fullCappedCampaigns.push(fullName);
									// delete capped campaign (when the cap time runs out, the ad can be loaded again)
									lsoCampaigns.splice(i, 1);
									// save lso
									lso.flush();
									trace("AdProxyUtils: getCappedCampaigns: Created frequency capped ad for " + lsoCampaign.campaign_name);
								}
							}
						}
					}
				}
			}
			return fullCappedCampaigns;
		}
		
		/**
		 * Create capped campaign in LSO and delele original campaign
		 * @param adData
		 * @param adManager
		 * @param lso
		 * @param cappedCampaigns
		 */
		static private function createCappedCampaign(adData:Object, adManager:AdManager, lso:SharedObject, cappedCampaigns:Array):String
		{
			var fullName:String;
			
			// check if already in LSO as capped type
			var found:Boolean = false;
			for each (var capCampaign:String in cappedCampaigns)
			{
				if (capCampaign == adData.campaign_name)
				{
					found = true;
					break;
				}
			}
			
			// if capped ad not found in array
			if (!found)
			{
				trace("AdProxyUtils: createCappedCampaign: frequency capped campaign has been added to the AS2 LSO for " + adData.campaign_name + " type: " + adData.campaign_type);
				
				// create a dummy campaign of type "capped" so that capped ad does not get overwritten by replacement ad
				var capCampaignObj:Object = new Object();
				capCampaignObj.campaign_name 				= adData.campaign_name;
				capCampaignObj.campaign_cap_count 			= adData.campaign_cap_count;
				capCampaignObj.campaign_cap_period 			= adData.campaign_cap_period;
				capCampaignObj.campaign_cap_group 			= adData.campaign_cap_group;
				capCampaignObj.campaign_cap_num_visits 		= adData.campaign_cap_num_visits;
				capCampaignObj.campaign_cap_first_visit		= adData.campaign_cap_first_visit;
				var vObj:Object = new Object();
				vObj.type = AdvertisingConstants.CAPPED_TYPE;
				vObj.prev_type = adData.campaign_type;
				vObj.campaign = capCampaignObj;
				
				// add capped campaign to LSO and capped campaign list
				lso.data.campaigns.push(vObj);
				cappedCampaigns.push(adData.campaign_name);
				fullName = adData.cms_name;
			}
			
			// store ad data so quest interiors will load
			var ad:AdData = adManager.getAdDataByCampaign(adData.campaign_name);
			// delete any campaigns from campaign list that match campaign name
			adManager.removeAdDataByName(adData.campaign_name, true);
			return fullName;
		}
		
		/**
		 * Determine if any capped campaigns have expired
		 * @return array of expired ad types
		 */
		static public function checkExpiredCappedCampaigns():Array
		{
			var expired:Array = [];
			
			// get campaign local data shared object
			var lso:SharedObject = getCampaignDataLSO();
			
			// get campaigns array from LSO
			var lsoCampaigns:Array = lso.data.campaigns;
			// if campaigns found
			if (lsoCampaigns)
			{
				var now:Date = new Date();
				var nowUTC:Number = Date.UTC(now.getFullYear(), now.getMonth(), now.getDate(), now.getHours(), now.getMinutes(), now.getSeconds());
				
				// check each campaign in LSO
				for (var i:int = lsoCampaigns.length-1; i != -1; i--)
				{
					// if capped campaign
					if (lsoCampaigns[i].type == AdvertisingConstants.CAPPED_TYPE)
					{
						var lsoCampaign:Object = lsoCampaigns[i].campaign;
						// if cap time has elapsed, then return true
						if (nowUTC - lsoCampaign.campaign_cap_first_visit > lsoCampaign.campaign_cap_period * 1000)
						{
							var prevType:String = lsoCampaigns[i].prev_type;
							trace("AdProxyUtils: checkExpiredCappedCampaigns: frequency capped campaign has expired: " + lsoCampaign.campaign_name + " type: " + prevType);
							// add to list if not already there
							if ((prevType) && (expired.indexOf(prevType) == -1))
								expired.push(prevType);
						}
					}
				}
			}
			return expired;
		}

		/**
		 * Copy main street campaign to custom island in LSO (for ad interior scenes)
		 * @param campaignName
		 */
		static public function saveCampaignToCustomIsland(campaignName:String):void
		{
			// get campaign data local shared object
			var lso:SharedObject = getCampaignDataLSO();
			
			// if campaign object is missing, then create it
			if (lso.data.campaigns == null)
				lso.data.campaigns = [];
			var campaigns:Array = lso.data.campaigns;
			
			// for each campaign in LSO
			for (var i:int = campaigns.length-1; i!=-1; i--)
			{
				// if custom island then delete
				if (campaigns[i].island == AdvertisingConstants.AD_ISLAND)
					campaigns.splice(i,1);
			}
			
			// for each campaign in LSO
			for each (var o:Object in campaigns)
			{
				var lsoCampaign:Object = o.campaign;
				// if match campaign name
				if (lsoCampaign.campaign_name == campaignName)
				{
					trace("AdProxyUtils :: Creating custom island for " + lsoCampaign.campaign_name);
					// copy to custom island
					// create LSO data object for campaign
					var lsoData:LsoData = new LsoData();
					// fill in properties from matching campaign object in LSO
					lsoData.type = AdCampaignType.MAIN_STREET;
					lsoData.island = AdvertisingConstants.AD_ISLAND;
					lsoData.offMain = 0;
					
					// for required properties
					for (var j:String in lsoCampaign)
					{
						lsoData.campaign.campaign_name 			= lsoCampaign.campaign_name;
						lsoData.campaign.click_through_URL 		= lsoCampaign.click_through_URL;
						lsoData.campaign.impression_URL 		= lsoCampaign.impression_URL;
						lsoData.campaign.campaign_file1 		= lsoCampaign.campaign_file1;
						lsoData.campaign.campaign_file2 		= lsoCampaign.campaign_file2;
					}
					campaigns.push(lsoData);
					
					// save LSO
					lso.flush();
					return;
				}
			}
			trace("AdProxyUtils :: no campaign match found when saving to Custom island.");
		}
		
		/**
		 * Get campaign for custom island from LSO  (for ad interior scenes)
		 * @param adManager
		 * @return Boolean returns true if found
		 */
		static public function getCampaignFromCustomIsland(adManager:AdManager):Boolean
		{
			// get campaign data local shared object
			var lso:SharedObject = getCampaignDataLSO();
			
			// if no campaign data, then return false
			if (lso.data.campaigns == null)
				return false;
			
			// get campaigns object from LSO
			var campaigns:Object = lso.data.campaigns;
			// for each campaign object
			for each (var o:Object in campaigns)
			{
				// if custom island
				if (o.island == AdvertisingConstants.AD_ISLAND)
				{
					trace("AdProxyUtils :: pulling custom campaign " + o.campaign.campaign_name);
					// create campaign object from LSO object
					createCampaignFromLSOObject(adManager, o, true, true);
					return true;
				}
			}
			return false;
		}
		
		// NAVIGATION FUNCTIONS ///////////////////////////////////////////////////////////
		
		/**
		 * If return scene then check LSO to get data for returning to originating scene
		 * @param	shellApi
		 * @param	destinationScene	destination scene from doors xml
		 * @return Boolean returns true if returning scene found
		 */
		static public function checkReturnScene(shellApi:ShellApi, destinationScene:String):Boolean
		{
			// if door destination is "return"
			if (destinationScene == "return")
			{
				return true;
			}
			return false;
		}
		
		// CACHING FUNCTIONS /////////////////////////////////////////////////////////
		
		/**
		 * Get cached tracking pixels local shared object 
		 * @return LSO
		 */
		static private function getTrackingPixelsLSO():SharedObject
		{
			var lso:SharedObject = SharedObject.getLocal("TrackingPixels", "/");
			lso.objectEncoding = ObjectEncoding.AMF0;
			return lso;
		}
		
		/**
		 * Save tracking pixel to LSO
		 * @param	url
		 */
		static public function cacheTrackingPixels(url:String):void
		{
			// get tracking pixels LSO
			var lso:SharedObject = getTrackingPixelsLSO();
			
			// create array if not created yet
			if (!lso.data.pixels)
				lso.data.pixels = new Array();
			
			// add URL to array and save
			lso.data.pixels.push(url);
			lso.flush();
		}
		
		/**
		 * Send cached tracking pixels from LSO
		 */
		static public function sendCachedTrackingPixels():void
		{
			// get tracking pixels LSO
			var lso:SharedObject = getTrackingPixelsLSO();
			
			// if array
			if (lso.data.pixels)
			{
				// send each pixel
				for each (var url:String in lso.data.pixels)
				{
					AdUtils.sendMobilePixel(url);
				}
				
				// clear array and save
				lso.data.pixels = null;
				delete lso.data.pixels;
				lso.flush();
			}
		}
		
		/**
		 * Cleans campaign data so that calls can be made to update the data
		 */
		static public function cleanOutCampaignData():void
		{
			var campDataSO:SharedObject = getCampaignDataLSO();
			var vCapsArray:Array = [];

			// clear islands
			if (campDataSO.data.islands != undefined)
				delete campDataSO.data.islands;
			
			// keep campaigns with frequency caps that are less than two months old
			if (campDataSO.data.campaigns != undefined)
			{
				var now:Date = new Date();
				var nowUTC:Number = Date.UTC(now.getFullYear(), now.getMonth(), now.getDate(), now.getHours(), now.getMinutes(), now.getSeconds());
				
				for (var i:Number = campDataSO.data.campaigns.length - 1; i != -1; i--)
				{
					var vCampaign:Object = campDataSO.data.campaigns[i];
					var campaignName:String = vCampaign.campaign.campaign_name;
					trace("cleanOutCampaignData :: Processing campaign: " + campaignName);
					// if extra capped campaigns
					var vFoundCap:Boolean = false;
					if (vCampaign.type == "capped")
					{
						for (var j:String in vCapsArray)
						{
							if (campaignName == vCapsArray[j])
							{
								vFoundCap = true;
								break;
							}
						}
					}
					// if no campaign cap then delete
					//trace("getCampaignInfo :: cap count for " + vCampaign.campaign.campaign_name + " is " + vCampaign.campaign.campaign_cap_count);
					if ((vCampaign.campaign.campaign_cap_count == null) || (vCampaign.campaign.campaign_cap_count == 0))
					{
						trace("cleanOutCampaignData :: Deleting uncapped campaign: " + campaignName);
						campDataSO.data.campaigns.splice(i, 1);
					}
					else if (nowUTC - vCampaign.campaign.campaign_cap_first_visit > vCampaign.campaign.campaign_cap_period * 1000)
					{
						trace("cleanOutCampaignData :: Deleting frequency cap campaign from LSO because it has expired: " + campaignName);
						campDataSO.data.campaigns.splice(i, 1);
					}
					else if (vFoundCap)
					{
						trace("cleanOutCampaignData :: Deleting extra frequency cap 'capped' campaign from LSO: " + campaignName);
						campDataSO.data.campaigns.splice(i, 1);
					}
					else
					{
						var timeRemaining:Number = -(nowUTC - vCampaign.campaign.campaign_cap_first_visit - vCampaign.campaign.campaign_cap_period * 1000)/1000/60/60;
						trace("cleanOutCampaignData :: Keep frequency cap campaign in LSO: " + campaignName + " Hours remaining: " + timeRemaining);
					}
					// add capped campaign name to array for checking in next iteration
					if (vCampaign.type == "capped")
					{
						vCapsArray.push(campaignName);
					}
				}
			}
			else
			{
				campDataSO.data.campaigns = [];
			}
			trace("cleanOutCampaignData :: campaigns left: " + campDataSO.data.campaigns.length);
			campDataSO.flush();
		}
	}
}
