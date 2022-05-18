package game.ar.ArPopup
{
	import game.util.DataUtils;
	
	public class ArAsset
	{
		public var asset:*;
		public var id:String;
		public var position:ArPositionData;
		public var emotes:Array = [];
		public function ArAsset(xml:XML = null)
		{
			parse(xml);
		}
		
		private function parse(xml:XML):void
		{
			position = new ArPositionData(xml);
			if(xml == null)
				return;
			
			if(xml.hasOwnProperty("asset"))
				asset = DataUtils.getString(xml.child("asset")[0]);
			
			if(xml.hasOwnProperty("@id"))
				id = DataUtils.getString(xml.attribute("id")[0]);
			
			if(xml.hasOwnProperty("emotes"))
			{
				var value:String = DataUtils.getString(xml.child("emotes")[0]);
				emotes = DataUtils.getArray(value);
			}
		}
	}
}