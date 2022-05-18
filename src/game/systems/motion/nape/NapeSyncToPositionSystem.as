package game.systems.motion.nape
{
	import game.data.motion.time.FixedTimestep;
	import game.nodes.motion.NapeSyncToPositionNode;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	
	import nape.phys.Body;
	
	public class NapeSyncToPositionSystem extends GameSystem
	{
		public function NapeSyncToPositionSystem()
		{
			super(NapeSyncToPositionNode, updateNode);
			super._defaultPriority = SystemPriorities.moveComplete;
			super.fixedTimestep = FixedTimestep.MOTION_TIME;
			super.linkedUpdate = FixedTimestep.MOTION_LINK;
		}
		
		public function updateNode(node:NapeSyncToPositionNode,time:Number) : void
		{	
			var body:Body = node.napeMotion.body;
			
			body.position.x = node.motion.x;
			body.position.y = node.motion.y;
			body.rotation = node.motion.rotation * 180 / Math.PI;
			body.velocity.x = node.motion.velocity.x;
			body.velocity.y = node.motion.velocity.y;
		}
	}
}