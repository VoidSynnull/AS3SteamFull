package game.scenes.hub.race
{
	import game.util.DataUtils;

	public class Reward
	{
		public var id:String;
		public var threshold:Number;
		public var reward:String;
		public function Reward(xml:XML = null)
		{
			parse(xml);
		}
		
		private function parse(xml:XML = null):void
		{
			if(xml == null)
				return;
			
			if(xml.hasOwnProperty("@id"))
				id = DataUtils.getString(xml.attribute("id")[0]);
			if(xml.hasOwnProperty("threshold"))
				threshold = DataUtils.getNumber(xml.child("threshold")[0]);
			if(xml.hasOwnProperty("reward"))
				reward = DataUtils.getString(xml.child("reward")[0]);
		}
	}
}