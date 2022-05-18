package game.systems.entity.character
{
	import game.components.entity.collider.PlatformCollider;
	import game.components.motion.Destination;
	import game.components.motion.MotionControl;
	import game.nodes.entity.character.CharacterMotionControlNode;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	import game.util.PlatformUtils;

	
	/**
	 * Manages character motion and animation state based on control input
	 */
	public class CharacterMotionControlSystem extends GameSystem
	{
		public function CharacterMotionControlSystem( )
		{
			super( CharacterMotionControlNode, updateNode );
			super._defaultPriority = SystemPriorities.moveControl;
		}
		
		private function updateNode(node:CharacterMotionControlNode, time:Number):void
		{
			updateTarget( node );
		}
		
		/**
		 * Update motion controls
		 * @param	node
		 * @param	time
		 */
		private function updateTarget(node:CharacterMotionControlNode ):void
		{
			var motionControl:MotionControl = node.motionControl;
			// don't allow autotarget until the user has input down.
			if ( motionControl.inputStateDown )
			{
				if(!PlatformUtils.isMobileOS)
				{
					node.charMotionControl.allowAutoTarget = true;
				}
			}
			
			// update forceReached
			if( motionControl.forceTarget )
			{
				motionControl.moveToTarget = !node.motionTarget.targetReached; 
				
				var destination:Destination = node.destination;
				if ( destination )
				{
					if( destination.active )
					{
						// check for scenario where destination should be interrupted
						if( !destination.lockControl && ( motionControl.inputStateChange && motionControl.inputStateDown ) )
						{
							destination.interrupt = true;
							// turn off ignore platforms TODO :: Ideally just do this once
							if ( destination.ignorePlatformTarget && node.platformCollider )
							{
								destination.ignorePlatformTarget = false;
								node.platformCollider.ignoreNextHit = false; 
							}
							return;
						}
						else if ( motionControl.moveToTarget && destination.ignorePlatformTarget )
						{
							checkPlatformObstruction( node );		// check for obstructions to target (only want to check for final point?)
						}
					}
					else
					{
						// turn off ignore platforms TODO :: Not sure if this is necessary or in what circumstances it would occur? - bard
						if ( destination.ignorePlatformTarget && node.platformCollider )
						{
							destination.ignorePlatformTarget = false;
							node.platformCollider.ignoreNextHit = false; 
						}
					}
				}
			}
			else if( !motionControl.lockInput )
			{
				if ( motionControl.inputActive && !checkInputDeadzone( node ) )
				{
					motionControl.moveToTarget = true;
				}
				else
				{
					motionControl.moveToTarget = false;
				}
			}
		}
		
		/**
		 * Determine if input is within deadzone.
		 * @param	node
		 * @return
		 */
		private function checkInputDeadzone(node:CharacterMotionControlNode):Boolean
		{
			if( Math.abs(node.motionTarget.targetDeltaX) < node.charMotionControl.inputDeadzoneX )
			{
				if(-node.motionTarget.targetDeltaY < -node.edge.rectangle.top && node.motionTarget.targetDeltaY < node.edge.rectangle.bottom )	// use characters edge to determine y deadzone
				{
					return true;
				}
			}
			return false;
		}

		/**
		 * Checks if charcater is positioned over a platform, but within range of target.
		 * If so allows character to pass through platform on next update.
		 * @param	node
		 * @return
		 */
		private function checkPlatformObstruction(node:CharacterMotionControlNode):void
		{
			if(node.motionTarget.minTargetDelta)
			{
				// minimum velocity before character is considered 'stopped'
				var minNavigationVelocity:int = 20;
				// minimum distance before we allow character to drop through a platform to reach a target.
				var minFallthroughDistanceY:Number = 40;
				
				if (node.motion.velocity.length < minNavigationVelocity)
				{
					var collider:PlatformCollider = node.entity.get(PlatformCollider);
					
					if(collider != null)
					{
						collider.ignoreNextHit = false;
						
						if(Math.abs(node.motionTarget.targetDeltaX * group.shellApi.viewportScale) < node.motionTarget.minTargetDelta.x)
						{
							if (node.motionTarget.targetDeltaY > minFallthroughDistanceY )
							{
								collider.ignoreNextHit = true;
								group.shellApi.logWWW("ChracterMoionControl :: ignore next hit");
							}
						}
					}
				}
			}
		}
	}
}
