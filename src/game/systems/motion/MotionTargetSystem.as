package game.systems.motion
{
	import game.components.motion.MotionTarget;
	import game.nodes.motion.MotionTargetNode;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	import game.util.Utils;
	
	/**
	 * Manages character motion and animation state based on control input
	 */
	public class MotionTargetSystem extends GameSystem
	{
		public function MotionTargetSystem( )
		{
			super( MotionTargetNode, updateNode );
			super._defaultPriority = SystemPriorities.move;
		}
		
		/**
		 * Update character motion and animation state based on control input
		 * @param	node
		 * @param	time
		 */
		private function updateNode(node:MotionTargetNode, time:Number):void
		{		
			var currentX:Number;
			var currentY:Number;

			var motionTarget:MotionTarget = node.motionTarget;
			
			if(node.motion)
			{
				currentX = node.motion.x;
				currentY = node.motion.y;
			}
			else
			{
				currentX = node.spatial.x;
				currentY = node.spatial.y;
			}
			
			// update target Delta
			if( motionTarget.targetOffset != null )
			{
				motionTarget.targetDeltaX =  ( motionTarget.targetX + motionTarget.targetOffset.x ) - currentX;
				motionTarget.targetDeltaY =  ( motionTarget.targetY + motionTarget.targetOffset.y ) - currentY;
			}
			else
			{
				motionTarget.targetDeltaX =  motionTarget.targetX - currentX;
				motionTarget.targetDeltaY =  motionTarget.targetY - currentY;
			}
							
			// check for target reached
			if ( motionTarget.checkReached )
			{
				motionTarget.targetReached = inRangeOfTarget( node );
			}
		}
		
		/**
		 * Determine if entity is within range of target
		 * @param	node
		 * @return
		 */
		private function inRangeOfTarget(node:MotionTargetNode):Boolean
		{
			var motionTarget:MotionTarget = node.motionTarget;
			if (!isNaN(motionTarget.minTargetPreciseDelta))
			{
				return(Utils.distance(node.spatial.x, node.spatial.y, motionTarget.targetX, motionTarget.targetY) < motionTarget.minTargetPreciseDelta);
			}
			else
			{
				if ( motionTarget.minTargetDelta )
				{
					return( Math.abs(motionTarget.targetDeltaX) < motionTarget.minTargetDelta.x && Math.abs(motionTarget.targetDeltaY) < motionTarget.minTargetDelta.y);
				}
				return false;
			}
		}
	}
}
