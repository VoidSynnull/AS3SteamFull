package game.data.ads
{
	import game.util.DataUtils;

	// needs to be dynamic as we will search on possible clickURL1 or clickURL2 properties
	dynamic public class AdData
	{
		public var campaign_type:String; // campaign type based on CMS values
		public var cms_name:String // campaign name pulled from the CMS
		public var campaign_name:String; // campaign name pulled from CMS without alias
		public var offMain:Boolean = false; // whether the ad is on/off main
		public var island:String;  // island where the ad should appear
		public var suffix:String; // campaign suffix for use in campaign name aliases
		public var unbranded:Boolean = false; // flag to indicate that campaign has branding removed (used for tracking)

		// TODO :: Could we convert this to a data class on AdData creation?  Having all the info as a string makes it difficult to manage. - bard
		// this propery is used to hold the left wrapper filename, autocard vars, NPC friend xml file, or checksums on mobile
		public var campaign_file1:String;
		// TODO :: Could we convert this to a data class on AdData creation?  Having all the info as a string makes it difficult to manage. - bard
		// this property is used to hold the right wrapper filename, or video file name
		public var campaign_file2:String;

		// Note: clickURL, impressionURL and videoFile can have numbers appended
		public var clickURL:String;
		public var impressionURL:String;
		public var videoFile:String; // usually a copy of campaign_file2

		// wrapper variables
		public var leftWrapper:String; // usually a copy of campaign_file1
		public var rightWrapper:String; // usually a copy of campaign_file2

		// frequency count properties
		public var campaign_cap_count:int = 0; // maximum campaign impressions within time period
		public var campaign_cap_period:int = 0; // number of milliseconds for time period
		public var campaign_cap_group:int = 0; //campaign id such as 15031501 to represent the CMS id of the per-user frequency cap group
		public var campaign_cap_num_visits:int = 0; // tally of campaign impressions within time period
		public var campaign_cap_first_visit:Number = 0; // UTC time logged for first impression (needs to be number to store long integer for UTC)

		/**
		 * Parse xml to AdData
		 * @param xml - Example of format :
			<billboard_ad>
				<campaign_type>Billboard</campaign_type>
				<campaign_name>GalacticHotDogsVideoBillboard</campaign_name>
				<clickURL>http://www.funbrain.com/galactichotdogs/</clickURL>
				<videoFile>video/GalacticHotDogs_300.flv</videoFile>
				<offMain>true</offMain>
			</billboard_ad>
		 */
		public function parseLocalXML( xml:XML ):void
		{
			var xmlList:XMLList = xml.children();
			var tagName:String;
			var value:String;

			// for each node
			for (var i:int = xmlList.length()-1; i!= -1; i--)
			{
				tagName = String(xmlList[i].name());
				value = String(xmlList[i]);
				// if tag name is offmain, convert to boolean
				if (tagName == "offMain")
				{
					this[tagName] = DataUtils.getBoolean(value);
				}
				else
				{
					// else use string value
					this[tagName] = value;
				}
			}
		}

		/**
		 *  check if campaign type is a mobile type
		 * @return boolean
		 *
		 */
		public function isMobileType():Boolean
		{
			return ( campaign_type.indexOf("Mobile") != -1 )
		}

		/**
		 * convert data object to string
		 * @return string
		 *
		 */
		public function toString():String
		{
			return ("[AdData type:"+campaign_type+" name:"+campaign_name+"]");
		}
	}
}
