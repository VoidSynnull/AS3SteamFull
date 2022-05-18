package game.data.ads
{
	/**
	 * Data object for campaign in LSO 
	 * @author VHOCKRI
	 */
	public class LsoCampaignData
	{
		public var campaign_name:String;
		public var click_through_URL:String;
		public var impression_URL:String;
		public var campaign_file1:String;
		public var campaign_file2:String;
		public var campaign_cap_count:int = 0; // maximum campaign impressions within time period
		public var campaign_cap_period:int = 0; // number of milliseconds for time period
		public var campaign_cap_group:int = 0; //campaign id such as 15031501 to represent the CMS id of the per-user frequency cap group
		public var campaign_cap_num_visits:int = 0; // tally of campaign impressions within time period
		public var campaign_cap_first_visit:Number = 0; // UTC time logged for first impression (needs to be number to store long integer for UTC)
		
		public function LsoCampaignData(adData:AdData = null):void
		{
			// if ad data, then update properties
			if (adData)
			{
				campaign_name 				= adData.campaign_name;
				click_through_URL 			= adData.clickURL;
				impression_URL 				= adData.impressionURL;
				campaign_file1 				= adData.campaign_file1;
				campaign_file2 				= adData.campaign_file2;
				campaign_cap_count	 		= getInt(adData.campaign_cap_count);
				campaign_cap_period 		= getInt(adData.campaign_cap_period);
				campaign_cap_group 			= getInt(adData.campaign_cap_group);
				campaign_cap_num_visits 	= getInt(adData.campaign_cap_num_visits);
				campaign_cap_first_visit 	= getNumber(adData.campaign_cap_first_visit);
			}
		}
		
		/**
		 * Get integer 
		 * @param value
		 * @return integer
		 */
		private function getInt(value:int):int
		{
			if (isNaN(value))
				return 0;
			else
				return value;
		}

		/**
		 * Get number for first visit UTC time
		 * @param value
		 * @return number
		 */
		private function getNumber(value:Number):Number
		{
			if (isNaN(value))
				return 0;
			else
				return value;
		}
	}
}