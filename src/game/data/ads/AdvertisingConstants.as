package game.data.ads
{
	public class AdvertisingConstants
	{
		// miscellaneous constants
		public static const AD_PATH_KEYWORD:String = "limited"; // name of folder used for ad content, also used in avatar part names for campaigns
		public static const AD_ISLAND:String = "Custom"; // name of ad island for ad interior scenes
		public static const CAPPED_TYPE:String = "capped"; // ad type for frequency capped ads
		public static const CAMPAIGN_SCENE_DELIMITER:String = "|"; // campaign scene delimiter used after scene class to indicate campaign name
		public static const CAMPAIGN_ALIAS_DELIMITER:String = "|"; // campaign alias delimiter used after campaign name when multiple campaigns use same files
		// example: game.scenes.custom.questInterior.QuestInterior|campaignScene=GalacticHotDogsQuest_Interior&entrance=true
		public static const MobileSuffix:String = "Mobile"; // default tracking suffix for mobile aliases
		public static const WebSuffix:String = "Web"; // default tracking suffix for web aliases

		// file names and directories
		public static const CAMPAIGN_FILE:String = "campaign.xml"; // name of campaign xml file
		public static const VERSION_FILE:String = "/version.xml"; // name of version xml file
		public static const MANIFEST_FILE:String = "/zipmanifest.xml"; // name of zip manifest xml file
		public static const AD_SETTINGS_FILE:String = AD_PATH_KEYWORD + "/adSettings.xml"; // name of ad settings xml file
		public static const AD_LOCAL_FILE:String = AD_PATH_KEYWORD + "/localAdData.xml"; // name of local ad data file
		public static const ZIP_DIRECTORY:String = "/zipfiles/ads/"; // directory of ad zip files on server

		// static lists
		public static const NON_ISLANDS:Array = ["start", "map", "custom", "clubhouse", "photoboothisland"]; // list of islands that don't have standard ads
		
		/*
		public static const MOBILE_ADS_LIST:Array = [AdCampaignType.MOBILE_MAP_AD1,
												AdCampaignType.MOBILE_MAP_AD2,
												AdCampaignType.MOBILE_MAP_AD3,
												AdCampaignType.MOBILE_MAP_AD4,
												AdCampaignType.MOBILE_MAP_AD5,
												AdCampaignType.MOBILE_MAP_AD6,
												AdCampaignType.MOBILE_MAP_AD7,
												AdCampaignType.MOBILE_MAP_AD8
												]; // list of map ad types
		*/
		public static const MAP_ADS_LIST:Array = [AdCampaignType.WEB_MAP_AD1,
												AdCampaignType.WEB_MAP_AD2,
												AdCampaignType.WEB_MAP_AD3,
												AdCampaignType.WEB_MAP_AD4,
												AdCampaignType.WEB_MAP_AD5,
												AdCampaignType.WEB_MAP_AD6,
												AdCampaignType.WEB_MAP_AD7,
												AdCampaignType.WEB_MAP_AD8
												]; // list of map ad types

		// tracking events (the rest are in AdTrackingConstants
		public static const TRACKING_CARD_ENLARGED:String = "CardEnlarged";
	}
}