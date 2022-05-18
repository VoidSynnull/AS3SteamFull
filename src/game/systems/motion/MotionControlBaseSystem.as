package game.systems.motion
{
	import game.components.motion.Destination;
	import game.components.motion.MotionControl;
	import game.components.motion.MotionTarget;
	import game.nodes.motion.MotionControlNode;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;

	public class MotionControlBaseSystem extends GameSystem
	{
		public function MotionControlBaseSystem()
		{
			super( MotionControlNode, updateNode );
			super._defaultPriority = SystemPriorities.moveControl;
		}
		
		/**
		 * Update motion based on control input
		 * @param	node
		 * @param	time
		 */
		private function updateNode(node:MotionControlNode, time:Number):void
		{
			var motionTarget:MotionTarget = node.motionTarget;
			var motionControl:MotionControl = node.motionControl;
			
			// update forceReached
			if( motionControl.forceTarget )
			{
				motionControl.moveToTarget = !( motionTarget.targetReached && !motionTarget.hasNextTarget );

				var destination:Destination = node.destination;
				if ( destination )
				{
					if( destination.active )
					{
						// check for scenario where destination should be interrupted
						if( !destination.lockControl && ( motionControl.inputStateChange && motionControl.inputStateDown ) )
						{
							destination.interrupt = true;
							return;
						}
					}
				}
			}
			else if( !motionControl.lockInput )
			{
				//if ( motionControl.inputActive && !checkInputDeadzone( node ) )
				if ( motionControl.inputActive )
				{
					motionControl.moveToTarget = true;
				}
				else
				{
					motionControl.moveToTarget = false;
				}
			}
			
			node.motionControlBase.accelerate = motionControl.moveToTarget;
		}
	}
}
