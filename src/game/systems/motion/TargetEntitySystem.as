/**
 * Follow another entity's spatial.
 * Tells following entity when to accelerate, but leaves how the following entity accelerates to other systems.
 */

package game.systems.motion
{
	import engine.ShellApi;
	
	import game.components.motion.MotionTarget;
	import game.components.motion.TargetEntity;
	import game.nodes.motion.TargetEntityNode;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	
	/**
	 * Follow another entity's spatial.
     * Tells following entity when to accelerate, but leaves how the following entity accelerates to other systems.
	 */
	public class TargetEntitySystem extends GameSystem
	{
		public function TargetEntitySystem()
		{
			super(TargetEntityNode, updateNode);
			super._defaultPriority = SystemPriorities.update;
		}
								
		private function updateNode(node:TargetEntityNode, time:Number):void
		{			
			var target:TargetEntity = node.targetEntity;
			
			if(target.target != null && target.active)
			{
				var motionTarget:MotionTarget = node.motionTarget;
				motionTarget.minTargetDelta = target.minTargetDelta;
				
				if(target.applyCameraOffset)
				{
					motionTarget.targetX = _shellApi.globalToScene(target.target.x, "x");
					motionTarget.targetY = _shellApi.globalToScene(target.target.y, "y");
				}
				else if(target.offset != null)
				{	
					motionTarget.targetX = target.target.x + target.offset.x;
					motionTarget.targetY = target.target.y + target.offset.y;
				}
				else
				{
					motionTarget.targetX = target.target.x;
					motionTarget.targetY = target.target.y;
				}
			}
		}
	
		[Inject]
		public var _shellApi:ShellApi;
	}
}
