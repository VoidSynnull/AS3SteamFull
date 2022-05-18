package game.systems.motion.nape
{
	import game.data.motion.time.FixedTimestep;
	import game.nodes.motion.PositionSyncToNapeNode;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	
	public class PositionSyncToNapeSystem extends GameSystem
	{
		public function PositionSyncToNapeSystem()
		{
			super(PositionSyncToNapeNode, updateNode);
			super._defaultPriority = SystemPriorities.moveComplete;
			super.fixedTimestep = FixedTimestep.MOTION_TIME;
			super.linkedUpdate = FixedTimestep.MOTION_LINK;
		}
		
		public function updateNode(node:PositionSyncToNapeNode, time:Number):void
		{	
			node.motion.x = node.napeMotion.body.position.x;
			node.motion.y = node.napeMotion.body.position.y;
			node.motion.rotation = node.napeMotion.body.rotation * 180 / Math.PI;
		}
	}
}