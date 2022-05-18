package game.data.ads
{
	import game.data.ads.LsoCampaignData;
	/**
	 * Data object for campaign in LSO 
	 * @author VHOCKRI
	 */
	public class LsoData
	{
		public var island:String;
		public var type:String;
		public var offMain:Number = 1;
		public var campaign:LsoCampaignData;
		
		public function LsoData(adData:AdData = null):void
		{
			// if ad data, then update properties
			if (adData)
			{
				island = adData.island;
				type = adData.campaign_type;
				// convert Boolean to 0 or 1
				offMain	= adData.offMain ? 1 : 0;
			}
			campaign = new LsoCampaignData(adData);
		}
	}
}
