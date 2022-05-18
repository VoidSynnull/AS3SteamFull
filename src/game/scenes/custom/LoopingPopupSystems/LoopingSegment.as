package game.scenes.custom.LoopingPopupSystems
{
	import ash.core.Entity;
	
	import game.util.DataUtils;
	
	public class LoopingSegment
	{
		public var bgId:String;
		public var distance:Number;
		public var entity:Entity;
		public var obstacles:Vector.<ObstacleData>;
		public function LoopingSegment(xml:XML = null)
		{
			parse(xml);
		}
		
		private function parse(xml:XML):void
		{
			if(xml == null)
				return;
			bgId = DataUtils.getString(xml.background);
			distance = DataUtils.getNumber(xml.distance);
			obstacles = new Vector.<ObstacleData>();
			if(xml.hasOwnProperty("obstacles"))
			{
				var children:XMLList = xml.child("obstacles")[0].children();
				for(var i:int = 0; i < children.length(); i++)
				{
					obstacles.push(new ObstacleData(children[i]));
				}
			}
			
		}
	}
}