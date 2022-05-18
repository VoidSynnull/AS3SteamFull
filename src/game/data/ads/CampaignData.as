package game.data.ads
{
	import flash.utils.Dictionary;
	
	import game.data.ParamList;
	import game.util.DataUtils;

	public class CampaignData
	{
		public function  CampaignData( xml:XML = null ):void
		{
			if( xml != null )
			{
				parse( xml );
			}
		}
		
		public var campaignId:String;
		public var version:uint = 1;				// version number (default to 1, version 2 don't reference sideStreet or mainStreet)
		public var video:String;	    			// video used by card only
		public var boycards:Vector.<String>;
		public var girlcards:Vector.<String>;
		public var clickUrls:ParamList;
		public var impressionOnClicks:ParamList;
		public var impressionUrls:ParamList;
		public var lockVideo:Boolean = true;
		public var gameID:String = "";				// game ID for quest game or popup game
		public var gameClass:String; 				// class name for popup game
		public var musicFile:String;
		public var popupScene:Boolean;
		public var messages:Dictionary;
		
		public function parse( xml:XML = null ):void
		{
			if( xml != null )
			{
				if( xml.hasOwnProperty("campaignId") )
				{
					this.campaignId = DataUtils.getString( xml.campaignId );
				}
				else
				{
					trace("Error :: CampaignData :: campaignId must be specified in xml." + xml );
				}
				
				// parse campaign version
				if( xml.hasOwnProperty("version") )
				{
					this.version = DataUtils.getUint( xml.version );
				}
				
				// parse video path
				if( xml.hasOwnProperty("video") )
				{
					this.video = DataUtils.getString( xml.video );
				}
				
				// parse lock video
				if( xml.hasOwnProperty("lockVideo") )
				{
					trace("video is locked: from parsed campaign.xml: " + xml.lockVideo);
					this.lockVideo = DataUtils.getBoolean( xml.lockVideo );
				}
				
				// parse urls
				if( xml.hasOwnProperty("clickUrls") )
				{
					clickUrls = new ParamList( XML(xml.clickUrls), "clickUrl" );
				}
				if( xml.hasOwnProperty("impressionOnClicks") )
				{
					impressionOnClicks = new ParamList( XML(xml.impressionOnClicks), "impressions" );
				}
				if( xml.hasOwnProperty("impressionUrls") )
				{
					impressionUrls = new ParamList( XML(xml.impressionUrls), "impressions" );
				}
				if( xml.hasOwnProperty("musicFile") )
				{
					musicFile = DataUtils.getString( xml.musicFile );
				}
				// parse  boy cards
				if( xml.hasOwnProperty("boycards") )
				{
					boycards = new Vector.<String>();
					var cardXMLs:XMLList = XML(xml.boycards).children();
					var numChildren:int = cardXMLs.length();
					for (var i:int = 0; i < numChildren; i++) 
					{
						boycards.push( DataUtils.getString(cardXMLs[i]) );
					}
				}
				// parse girl cards
				if( xml.hasOwnProperty("girlcards") )
				{
					girlcards = new Vector.<String>();
					cardXMLs = XML(xml.girlcards).children();
					numChildren = cardXMLs.length();
					for (i = 0; i < numChildren; i++) 
					{
						girlcards.push( DataUtils.getString(cardXMLs[i]) );
					}
				}
				
				if( xml.hasOwnProperty("messageChanges") )
				{
					if (messages == null) {
						messages = new Dictionary();
					}
					cardXMLs = XML(xml.messageChanges).children();
					numChildren = cardXMLs.length();
					for (i = 0; i < numChildren; i++) {
						var message:XML = cardXMLs[i];
						var id:String = "default";
						if(message.hasOwnProperty("@id"))
							id = DataUtils.getString(message.attribute("id")[0]);
						messages[id] = new MessageData(message);
					}
				}
				
				trace( "CampaignData: xml given, defined campaign " + this.campaignId + " from xml");
			}
			else
			{
				trace( "CampaignData: xml was null, failed to define campaign " + this.campaignId + " from xml");
			}
		}
	}
}