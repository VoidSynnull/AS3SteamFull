package game.systems.motion
{
	import flash.geom.Point;
	
	import game.nodes.motion.DraftNode;
	import game.systems.GameSystem;
	import game.util.PointUtils;
	
	public class DraftSystem extends GameSystem
	{
		public function DraftSystem()
		{
			super(DraftNode, updateNode);
		}
		
		private function updateNode(node:DraftNode, time:Number):void
		{
			var targetRotation:Number = PointUtils.getRadiansOfTrajectory(node.draft.motion.velocity) * 180 / Math.PI + 90;
			if(node.draft.motion.velocity.equals(new Point()))
				targetRotation = 0;
			var difference:Number = targetRotation - node.sptial.rotation;
			if(difference > 180)
				difference -=360;
			if(difference <-180)
				difference += 360;
			node.motion.rotationVelocity = difference * node.draft.gravityDampening;
		}
	}
}