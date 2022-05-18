package game.systems.entity.character.states 
{
	import game.components.animation.FSMControl;
	import game.components.entity.character.CharacterMovement;
	import game.data.animation.entity.character.Push;

	/**
	 * ...
	 * @author Bard McKinley
	 */
	public class PushState extends CharacterState
	{
		public function PushState()
		{
			super.type = CharacterState.PUSH;
		}
		
		override public function check():Boolean
		{
			// check for x velocity & wall isHit (if isHit manages the velocity, isHit may suffice)
			// return node.wallCollider.isHit;
			return (node.wallCollider.isHit);
		}
		
		/**
		 * Start the state
		 */
		override public function start():void 
		{
			super.setAnim(Push);
			node.charMotionControl.ignoreVelocityDirection = false;
			node.charMotionControl.directionByVelocity = true;
			if(node.spatial.scaleX < 0 && node.wallCollider.direction < 0 || node.spatial.scaleX > 0 && node.wallCollider.direction > 0)
				node.spatial.scaleX *= -1;
			if( node.wallCollider.isHit )
			{
				node.charMovement.state = CharacterMovement.NONE;
			}
			else if( node.wallCollider.isPushing )
			{
				node.charMovement.state = CharacterMovement.GROUND;
			}
		}
		
		override public function exit():void
		{
			node.wallCollider.isHit = node.wallCollider.isPushing = false;	// set hit to false to prevent state loop, hit will get updated again during update 
		}
		
		/**
		 * Manage the state
		 */
		override public function update( time:Number ):void
		{
			var fsmControl:FSMControl = node.fsmControl;

			if ( fsmControl.check(CharacterState.HURT) )			// check for hazard collision
			{
				fsmControl.setState( CharacterState.HURT );
			}
			else if ( fsmControl.check(CharacterState.FALL) )		// check for platform collision		
			{
				fsmControl.setState( CharacterState.FALL );
			}
			else if ( node.motionControl.moveToTarget/* || !node.motionControl.inputActive*/ )		// direction check
			{
				if ( fsmControl.check(CharacterState.JUMP) )		// check for jump
				{
					fsmControl.setState( CharacterState.JUMP ); 
				}
				else if ( fsmControl.check(CharacterState.DUCK) )	// check for jump
				{
					fsmControl.setState( CharacterState.DUCK ); 
				}
				else if( switchedDirection() )
				{
					if ( fsmControl.check(CharacterState.WALK) )	// check run
					{
						fsmControl.setState( CharacterState.WALK ); 
					}
					else
					{
						fsmControl.setState( CharacterState.STAND ); 
					}
				}
			}
			else /*if( Math.abs(node.motion.velocity.x) < node.charMotionControl.walkSpeed )*/	// check stand
			{
				node.motion.zeroMotion("x");
				fsmControl.setState( CharacterState.STAND ); 
			}
		}
		
		private function switchedDirection():Boolean
		{
			return(super.node.motionTarget.targetDeltaX > 0 && super.node.wallCollider.direction < 0 ||
			       super.node.motionTarget.targetDeltaX < 0 && super.node.wallCollider.direction > 0);
		}
	}
}