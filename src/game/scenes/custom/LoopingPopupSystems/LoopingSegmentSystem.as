package game.scenes.custom.LoopingPopupSystems
{
	import game.components.entity.MotionMaster;
	import game.systems.GameSystem;
	
	public class LoopingSegmentSystem extends GameSystem
	{
		public function LoopingSegmentSystem()
		{
			super(LoopingSegmentPieceNode, updateNode);
		}
		
		private function updateNode(node:LoopingSegmentPieceNode, time:Number):void
		{
			var master:MotionMaster = node.segment.master;
			if(!master.active)
				return;
			
			node.motion.parentVelocity = master.velocity;
		}
	}
}