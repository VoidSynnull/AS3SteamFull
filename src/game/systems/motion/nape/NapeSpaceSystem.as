package game.systems.motion.nape
{
	import ash.core.Engine;
	
	import game.data.motion.time.FixedTimestep;
	import game.nodes.motion.NapeSpaceNode;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	
	public class NapeSpaceSystem extends GameSystem
	{
		public function NapeSpaceSystem()
		{
			super(NapeSpaceNode, updateNode, null, nodeRemoved);
			super._defaultPriority = SystemPriorities.move;
			super.fixedTimestep = FixedTimestep.MOTION_TIME;
			super.linkedUpdate = FixedTimestep.MOTION_LINK;
		}
		
		public function updateNode(napeSpaceNode:NapeSpaceNode, time:Number):void
		{
			napeSpaceNode.napeSpace.space.step(time)
			
			//only show debug if debug isn't null - during dev/testing
			if(napeSpaceNode.napeSpace.debug != null)
			{			
				napeSpaceNode.napeSpace.debug.clear();
				napeSpaceNode.napeSpace.debug.draw(napeSpaceNode.napeSpace.space);
				napeSpaceNode.napeSpace.debug.flush();
			}
		}
		
		override public function removeFromEngine(systemsManager:Engine) : void
		{
			systemsManager.releaseNodeList(NapeSpaceNode);
		}
		
		private function nodeRemoved(node:NapeSpaceNode):void
		{
			node.napeSpace.space.clear();
		}
	}
}