package game.scenes.shrink.livingRoomShrunk.StaticSystem
{
	import game.systems.GameSystem;
	
	public class StaticSystem extends GameSystem
	{
		public function StaticSystem()
		{
			super(StaticNode, updateNode);
		}
		
		public function updateNode(node:StaticNode, time:Number):void
		{
			if(node.static.inContact || node.static.looseChargeOverTime)
				node.static.discharge(time);
			
			node.static.inContact = false;
			node.static.contact = null;
		}
	}
}