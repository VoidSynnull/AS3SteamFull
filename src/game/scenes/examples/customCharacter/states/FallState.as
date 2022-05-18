package game.scenes.examples.customCharacter.states
{
	import game.components.entity.character.CharacterMotionControl;
	import game.components.entity.character.CharacterMovement;
	import game.systems.entity.character.states.CharacterState;

	public class FallState extends CustomCharacterState
	{
		public function FallState()
		{
			super.type = CharacterState.FALL;
		}
		
		override public function check():Boolean
		{
			return !node.platformCollider.isHit;
		}
		
		/**
		 * Start the state
		 */
		override public function start():void
		{
			/*
			if( !node.characterMotionControl.spinning )
			{
				setAnim( Fall );
			}
			*/
			node.characterMotionControl.ignoreVelocityDirection = true;
			node.characterMovement.state = CharacterMovement.AIR;
		}
		
		/**
		 * Manage the state
		 */
		override public function update( time:Number ):void
		{
			var charControl:CharacterMotionControl = node.characterMotionControl;
			
			if ( node.fsmControl.check(CharacterState.HURT) )		// check for hazard collision
			{
				node.motionControl.moveToTarget = false;
				node.fsmControl.setState( CharacterState.HURT );
				return;
			}
			else if ( node.fsmControl.check(CharacterState.CLIMB) )	// check for climb collision
			{
				node.motionControl.moveToTarget = false;
				node.fsmControl.setState( CharacterState.CLIMB );
				return;
			}
			else if ( node.platformCollider.isHit )	// check for platform collision
			{
				if ( Math.abs(node.motion.velocity.x) > node.characterMotionControl.runSpeed )
				{
					super.directionByVelocity();
				}
				
				node.fsmControl.setState( CharacterState.LAND );
				return;
			}
			else if ( node.fsmControl.check(CharacterState.SWIM) )	// check for platform collision
			{
				// TODO :: Go right to Swim, and let swim handle landing?
				node.motionControl.moveToTarget = false;	
				node.fsmControl.setState( CharacterState.LAND );
				return;
			}
			
			// check to see if velocity has reversed, if restart Fall anim
		}
	}
}