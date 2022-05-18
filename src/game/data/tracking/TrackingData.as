package game.data.tracking
{
	import game.util.DataUtils;

	/**
	 * Data class to hold standard tracking variables
	 * @author umckiba
	 *
	 */
	public class TrackingData
	{
		public function TrackingData( xml:XML = null )
		{
			if( xml != null )
			{
				parse(xml);
			}
		}

		public var event:String;
		public var choice:String;
		public var subChoice:String;
		public var campaign:String;
		public var numValLabel:String;
		public var numVal:Number;
		public var count:String;

		public function parse( xml:XML ):void
		{
			// TODO :: parse xml to tracking data
			if( xml.hasOwnProperty("event") )
			{
				this.event = DataUtils.getString( xml.event );
			}
			if( xml.hasOwnProperty("choice") )
			{
				this.choice = DataUtils.getString( xml.choice );
			}
			if( xml.hasOwnProperty("subChoice") )
			{
				this.subChoice = DataUtils.getString( xml.subChoice );
			}
			if( xml.hasOwnProperty("campaign") )
			{
				this.campaign = DataUtils.getString( xml.campaign );
			}
			if( xml.hasOwnProperty("numValLabel") )
			{
				this.numValLabel = DataUtils.getString( xml.numValLabel );
			}
			if( xml.hasOwnProperty("numVal") )
			{
				this.numVal = DataUtils.getNumber( xml.numVal );
			}
			if( xml.hasOwnProperty("count") )
			{
				this.count = DataUtils.getString( xml.count );
			}
		}

	}
}

