package game.scenes.shrink.livingRoomShrunk.StaticSystem
{
	import game.systems.GameSystem;
	
	public class StaticClimbSystem extends GameSystem
	{
		public function StaticClimbSystem()
		{
			super(StaticClimbNode, updateNode);
		}
		
		public function updateNode(node:StaticClimbNode, time:Number):void
		{
			if(node.climb.isHit)
			{
				var static:Static = node.hit.hit.get(Static);
				if(static != null)
					node.static.contactStaticObject(static);
			}
		}
	}
}