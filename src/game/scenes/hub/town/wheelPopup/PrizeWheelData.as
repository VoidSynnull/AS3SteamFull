package game.scenes.hub.town.wheelPopup
{
	import flash.utils.Dictionary;
	
	import game.util.DataUtils;
	import game.util.GeomUtils;
	
	public class PrizeWheelData
	{
		public var asset:String;
		public var prizes:Vector.<PrizeData>;
		public var inventory:Dictionary;
		public var test:Boolean = false;
		
		public function PrizeWheelData(xml:XML = null)
		{
			prizes = new Vector.<PrizeData>();
			inventory = new Dictionary();
			parse(xml);
		}
		
		private function parse(xml:XML):void
		{
			if(xml == null)
				return;
			
			if(xml.hasOwnProperty("@test"))
				test = DataUtils.getString(xml.attribute("test")[0]);
			
			if(xml.hasOwnProperty("asset"))
				asset = DataUtils.getString(xml.child("asset")[0]);
			
			var childXml:XML;
			var list:XMLList;
			
			if(xml.hasOwnProperty("prizes"))
			{
				childXml = xml.child("prizes")[0];
				list = childXml.children();
				for(var i:int = 0; i < list.length(); ++i)
				{
					prizes.push(new PrizeData(list[i]));
				}
			}
			
			if(xml.hasOwnProperty("inventory"))
			{
				childXml = xml.child("inventory")[0];
				list = childXml.children();
				var prizeInvetory:PrizeInventoryData;
				for(i = 0; i < list.length(); ++i)
				{
					prizeInvetory = new PrizeInventoryData(list[i]);
					inventory[prizeInvetory.id] = prizeInvetory;
				}
			}
		}
		
		public function getRandomPrizeFromInventory(id:String):PrizeData
		{
			var typeInventory:PrizeInventoryData = inventory[id];
			if(typeInventory)
			{
				if(typeInventory.prizes.length == 0)
					return null;
				var index:int = GeomUtils.randomInt(0, typeInventory.prizes.length - 1);
				return typeInventory.prizes[index];
			}
			return null;
		}
	}
}