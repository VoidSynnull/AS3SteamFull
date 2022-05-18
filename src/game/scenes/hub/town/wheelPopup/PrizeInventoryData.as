package game.scenes.hub.town.wheelPopup
{
	import game.util.DataUtils;
	
	public class PrizeInventoryData
	{
		public var id:String;
		public var prizes:Vector.<PrizeData>;
		public function PrizeInventoryData(xml:XML = null)
		{
			prizes = new Vector.<PrizeData>();
			parse(xml);
		}
		
		private function parse(xml:XML):void
		{
			if(xml == null)
				return;
			
			if(xml.hasOwnProperty("@id"))
				id = DataUtils.getString(xml.attribute("id")[0]);
			
			var list:XMLList = xml.children();
			for(var i:int = 0; i < list.length(); ++i)
			{
				prizes.push(new PrizeData(list[i]));
			}
		}
	}
}