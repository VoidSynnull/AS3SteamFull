package game.systems.motion
{
	import game.components.motion.AccelerateToTargetRotation;
	import game.data.motion.time.FixedTimestep;
	import game.nodes.motion.AccelerateToTargetRotationNode;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	import game.util.GeomUtils;
	
	public class AccelerateToTargetRotationSystem extends GameSystem
	{
		public function AccelerateToTargetRotationSystem()
		{
			super(AccelerateToTargetRotationNode, updateNode);
			super._defaultPriority = SystemPriorities.move;
			
			super.fixedTimestep = FixedTimestep.MOTION_TIME;
			super.linkedUpdate = FixedTimestep.MOTION_LINK;
		}
		
		private function updateNode(node:AccelerateToTargetRotationNode, time:Number):void
		{
			var accelerateToTarget:AccelerateToTargetRotation = node.accelerateToTargetRotation;
			node.motion.rotationAcceleration = 0;
			
			if(!accelerateToTarget.lock)
			{
				var originX:Number = node.motion.x;
				var originY:Number = node.motion.y;
				var initialRotation:Number = node.spatial.rotation;
				var targetDeltaX:Number = node.motionTarget.targetDeltaX;	
				var targetDeltaY:Number = node.motionTarget.targetDeltaY;
				var degrees:Number = GeomUtils.radianToDegree(Math.atan2(targetDeltaY, targetDeltaX));
				var angleDelta:Number = initialRotation - degrees;
				
				// rotation correction must be done on spatial to work with smoothing.
				if (angleDelta < -180)
				{
					node.spatial.rotation = initialRotation + 360;
					angleDelta += 360;
				}
				else if (angleDelta >= 180)
				{
					node.spatial.rotation = initialRotation - 360;
					angleDelta -= 360;
				}
				
				if(Math.abs(angleDelta) > accelerateToTarget.deadZone)
				{								
					if (angleDelta > 0)
					{
						node.motion.rotationAcceleration = -accelerateToTarget.rotationAcceleration;
					}
					else if(angleDelta < 0)
					{
						node.motion.rotationAcceleration = accelerateToTarget.rotationAcceleration;
					}
				}
			}
		}
	}
}
