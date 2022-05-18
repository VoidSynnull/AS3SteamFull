package game.scenes.hub.town.wheelPopup
{
	import game.util.DataUtils;
	
	public class PrizeData
	{
		public var id:String;
		public var weight:Number;
		public var type:String;
		public var prize:String;
		public var unique:Boolean;
		public var gender:String;
		public function PrizeData(xml:XML)
		{
			parse(xml);
		}
		
		private function parse(xml:XML):void
		{
			if(xml == null)
				return;
			
			if(xml.hasOwnProperty("@type"))
				type = DataUtils.getString(xml.attribute("type")[0]);
			
			if(xml.hasOwnProperty("@id"))
				id = DataUtils.getString(xml.attribute("id")[0]);
			
			if(xml.hasOwnProperty("@gender"))
				gender = DataUtils.getString(xml.attribute("gender")[0]);
			
			if(xml.hasOwnProperty("@weight"))
				weight = DataUtils.getNumber(xml.attribute("weight")[0]);
			
			if(xml.hasOwnProperty("@unique"))
				unique = DataUtils.getBoolean(xml.attribute("unique")[0]);
			
			prize = DataUtils.getString(xml);
		}
	}
}