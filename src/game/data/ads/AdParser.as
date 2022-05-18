package game.data.ads
{
	import com.poptropica.AppConfig;
	
	import game.data.ads.AdCampaignType;
	import game.data.ads.AdvertisingConstants;
	
	public class AdParser
	{
		// here is the form of the data returned by CMS:
		/*
		{
			"on_main": {
				"Main Street": {
					"campaign_type":           "Main Street",
					"campaign_name":           "Galactic Hot Dogs Quest",
					"campaign_file1":          "checksum1,questchecksum1",
					"campaign_file2":          "video/galactichotdogs.flv",
					"click_through_URL":       "http://galactichotdogs.com",
					"impression_URL":          "",
					"campaign_groups":         {"Per-User Cap Group": 15031501},
					"campaign_cap_count":      "1",
					"campaign_cap_period":     "3600"
				},
			},
			"off_main": {
				"Billboard": {
					"campaign_type":           "Billboard",
					"campaign_groups":         {"Per-User Cap Group": 15031500},
					...
				},
				"Per-User Cap Group": {
					15031500: {
						"campaign_type":           "Per-User Cap Group",
						"campaign_cap_count":      "7",
						"campaign_cap_period":     "172800",
						...
					},
					15031501: {
						"campaign_type":           "Per-User Cap Group",
						"campaign_cap_count":      "5",
						"campaign_cap_period":     "3600",
						...
					},
				},
				"Wrapper": {
					"campaign_type":   "Wrapper",
					"campaign_groups": {"Per-User Cap Group": 15031500},
					...
				},
			},
		}
		*/
		
		/**
		 * Parse AMFPHP data returned from CMS 
		 * @param o AMFPHP object
		 * @param island
		 * @return vector of AdData
		 * 
		 */
		public function parseAMFPHP(o:Object, island:String):Vector.<AdData>
		{
			// create vector list
			var list:Vector.<AdData> = new Vector.<AdData>();
			
			// get off main campaigns first and per user cap groups which are off main
			var newList:Vector.<AdData> = parseDataAMFPHP(o.off_main, true, island);
			for each (var data:AdData in newList)
			{
				list.push(data);
			}
			// get on main campaigns
			newList = parseDataAMFPHP(o.on_main, false, island);
			for each (data in newList)
			{
				list.push(data);
			}
			
			// check per user cap groups against list and apply frequency caps to affected campaigns
			for each (data in list)
			{
				// if campaign has frequency cap
				if ((data.campaign_cap_group) && (data.campaign_cap_group != 0))
				{
					// get frequency cap group by ID
					var capGroup:AdData = _perUserCapGroups[data.campaign_cap_group];
					// if found corresponding cap group, then update cap count and cap period
					if (capGroup)
					{
						trace("AdParser: applying frequency cap values to campaign " + data.campaign_name + ", count=" + capGroup.campaign_cap_count + ", period=" + capGroup.campaign_cap_period);
						data.campaign_cap_count = capGroup.campaign_cap_count;
						data.campaign_cap_period = capGroup.campaign_cap_period;
					}
				}
			}
			return list;
		}
				
		/**
		 * Parse AMFPHP object for off main or on main 
		 * @param o AMFPHP object
		 * @param offMain Boolean
		 * @param island
		 * @return vector of AdData
		 * 
		 */
		private function parseDataAMFPHP(o:Object, offMain:Boolean, island:String):Vector.<AdData>
		{
			// create vector list
			var list:Vector.<AdData> = new Vector.<AdData>();
			
			// for each campaign type in object
			for (var campaignType:String in o)
			{
				// get single campaign object
				var ad:Object = o[campaignType];
				// check campaign type
				switch (campaignType)
				{
					// if per user cap group (can have multiple groups)
					case AdCampaignType.PER_USER_CAP_GROUP:
						// for each cap count id
						for (var id:int in ad)
						{
							// parse cap group data and add to per user cap groups object
							var capAdData:AdData = parseAdObject(ad[id]);
							trace("AdParser: per-user cap group with id=" + id + ", count=" + capAdData.campaign_cap_count + ", period=" + capAdData.campaign_cap_period);
							_perUserCapGroups[id] = capAdData;
						}
						// don't add to list, so skip
						continue;
						
					// main street campaign types
					case AdCampaignType.MAIN_STREET:
					case AdCampaignType.MAIN_STREET2:
					case AdCampaignType.MAIN_STREET3:
					case AdCampaignType.NPC_FRIEND:
					case AdCampaignType.VENDOR_CART:
					case AdCampaignType.WEB_PHOTO_BOOTH:
					case AdCampaignType.WEB_BLIMP:
					case AdCampaignType.AUTOCARD:
					case AdCampaignType.WEB_SCAVENGER_ITEM:
						// don't add these add types if offMain
						if (offMain)
							continue;
						else
							break;
						
					// all other campaign types
					default:
						// if carousel and off main then skip
						if ((campaignType.indexOf("Carousel") != -1) && (offMain))
							continue;
						else
							break;
				}
				// set island and off main flag
				ad.island = island;
				ad.offMain = offMain;
				// add to list
				list.push(parseAdObject(ad));
			}
			return list;
		}
		
		/**
		 * Creates <class>AdData</class> object from the passed Object
		 * @param ad_object - Object initially retrieved from LSO or CMS, contains data concerning a particular ad
		 * @return  - AdData object, converted from passed Object
		 * 
		 */
		static public function parseAdObject(ad_object:Object):AdData
		{
			// create new adData object
			var data:AdData = new AdData();
			
			// transer values
			data.campaign_type = ad_object.campaign_type;
			data.cms_name = ad_object.campaign_name;
			data.island = ad_object.island;
			
			// check for campaign name suffixes
			var index:int = data.cms_name.indexOf(AdvertisingConstants.CAMPAIGN_ALIAS_DELIMITER);
			// if suffix used, then save it
			if (index != -1)
			{
				data.suffix = data.cms_name.substr(index + 1);
				data.campaign_name = data.cms_name.substr(0, index);
			}
			else
			{
				// if no suffix then use defaults
				data.campaign_name = data.cms_name;
				//if (AppConfig.mobile)
				//	data.suffix = AdvertisingConstants.MobileSuffix;
				//else
				//	data.suffix = AdvertisingConstants.WebSuffix;
				data.suffix = "";
			}
			
			// offMain is Boolean but incoming value might be 0 or 1 when coming from LSO
			data.offMain = ad_object.offMain;
			trace("AdParser :: parseAdObject : campaign:" + data.campaign_name + ", type:" + data.campaign_type + ", offMain: " + data.offMain + ", island:" + data.island);
			
			data.campaign_file1 = ad_object.campaign_file1;
			data.campaign_file2 = ad_object.campaign_file2;		
			
			// Note: these properies are renamed to be shorter and match the xml ID values
			data.clickURL = ad_object.click_through_URL;
			data.impressionURL = ad_object.impression_URL;
			
			// set empty strings to null
			if (data.clickURL == "")
				data.clickURL = null;
			if (data.impressionURL == "")
				data.impressionURL = null;
			
			// get frequency cap properties (forced to zero if null)
			data.campaign_cap_count = int(getCampaignNumber(ad_object.campaign_cap_count));
			data.campaign_cap_period = int(getCampaignNumber(ad_object.campaign_cap_period));
			data.campaign_cap_num_visits = int(getCampaignNumber(ad_object.campaign_cap_num_visits));
			data.campaign_cap_first_visit = getCampaignNumber(ad_object.campaign_cap_first_visit);
			
			// look for cap groups
			if (ad_object.campaign_groups)
			{
				// if cap group, get cap group ID and attach to frequency cap group property (default is zero)
				var capGroupID:int = ad_object.campaign_groups["Per-User Cap Group"];
				if (capGroupID)
				{
					trace("AdParser :: parseAdObject : campaign:" + data.campaign_name + " has frequency cap group of id " + capGroupID);
					data.campaign_cap_group = capGroupID;
				}
			}
			
			// split any comma-delimited values into multiple properties attached to AdData object
			splitIntoProperties("clickURL", data);
			splitIntoProperties("impressionURL", data);				
			
			// ad type specific variables
			switch(ad_object.campaign_type)
			{
				// if wrapper, then need to prefix wrapper names with "as3_"
				case AdCampaignType.WRAPPER:
					data.leftWrapper = parseWrapperPath(ad_object.campaign_file1);
					data.rightWrapper = parseWrapperPath(ad_object.campaign_file2);
					break;
				
				// for campaigns that have videos
				case AdCampaignType.MAIN_STREET:
				case AdCampaignType.MAIN_STREET2:
				case AdCampaignType.WEB_BLIMP:
					// copy campaign_file2 value into videoFile property (need this for splitIntoProperties to work)
					data.videoFile = ad_object.campaign_file2;
					// split any comma-delimited values into multiple videoFile properties attached to AdData object
					splitIntoProperties("videoFile", data);
					break;
			}
			return data;
		}
		
		/**
		 * Get campaign property number 
		 * @param value
		 * @return Number
		 */
		static private function getCampaignNumber(value:Number):Number
		{
			if (isNaN(value))
				return 0;
			else
				return value;
		}
		
		/**
		 * explode varible into multiple variables and append with numbers 1, 2, 3, etc.
		 */
		/**
		 * Explode comma-delimited string into multiple properties attached to the data object
		 * Propery key name is "name" appended with numbers 1, 2, 3, etc. based on position in string list
		 * Example: clickURL1:value, clickURL2:value, clickURL3:value
		 * @param name base name for property key
		 * @param data object
		 * 
		 */
		static private function splitIntoProperties(name:String, data:Object):void
		{
			var vList:Array;
			var vValue:String = data[name];
			if ((vValue != null) && (vValue.indexOf(",") != -1))
			{
				vList = vValue.split(",");
				var vLen:int = vList.length;
				if (vLen > 1)
				{
					for (var i:int = 0; i != vLen; i++)
						data[name + String(i+1)] = vList[i];
				}
			}
		}
		
		/**
		 * Convert wrapper path to have "as3_" appended
		 * @param aPath
		 * @return String
		 * 
		 */
		static private function parseWrapperPath(aPath:String):String
		{
			// incoming path is images/surroundX_name.jpg or images/surroundX_name.swf or images/flash/surroundX_name.swf
			// jpg path is images/as3_surroundX_name.jpg
			// iframe html5 path is images/wrappers/as3_surroundX_name/wrapper.html
			var vPrefix:String = "as3_";
			var vSplit:Array = aPath.split("/");
			// get file name
			var vFile:String = vSplit[vSplit.length-1];
			var dotIndex:int = vFile.indexOf(".");
			// if jpg
			if (vFile.indexOf(".jpg") != -1)
			{
				return (vSplit[0] + "/" + vPrefix + vFile);
			}
			else
			{
				// if iframe html
				return (vSplit[0] + "/wrappers/" + vPrefix + vFile.substr(0, dotIndex) + "/wrapper.html");
			}
		}

		private var _perUserCapGroups:Object = {};
	}
}
