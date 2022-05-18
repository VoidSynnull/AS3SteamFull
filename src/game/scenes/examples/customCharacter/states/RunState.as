package game.scenes.examples.customCharacter.states
{
	import game.components.animation.FSMControl;
	import game.components.entity.character.CharacterMotionControl;
	import game.components.entity.character.CharacterMovement;
	import game.systems.entity.character.states.CharacterState;

	public class RunState extends CustomCharacterState 
	{
		public function RunState()
		{
			super.type = CharacterState.RUN;
		}
		
		override public function check():Boolean
		{
			return Math.abs(node.motion.velocity.x) >= node.characterMotionControl.runSpeed;
		}
		
		/**
		 * Start the state
		 */
		override public function start():void
		{
			super.setAnim(super.animationId);
			node.characterMotionControl.ignoreVelocityDirection = false;
			node.characterMotionControl.directionByVelocity = true;
			node.characterMovement.state = CharacterMovement.GROUND;
			
			//SkinUtils.setEyeStates( node.entity, EyeSystem.SQUINT, EyeSystem.FRONT, false );
		}
		
		/**
		 * Manage the state
		 */
		override public function update( time:Number ):void
		{
			var charControl:CharacterMotionControl = node.characterMotionControl;
			var fsmControl:FSMControl = node.fsmControl;
			
			if ( fsmControl.check(CharacterState.HURT) )			// check for platform collision
			{
				fsmControl.setState( CharacterState.HURT );
				return;
			}
			else if ( fsmControl.check(CharacterState.FALL) )		// check for platform
			{
				fsmControl.setState( CharacterState.FALL );
				return;
			}
			else if ( fsmControl.check(CharacterState.JUMP) && (node.motionControl.moveToTarget || !node.motionControl.inputActive))			// check for jump
			{
				fsmControl.setState( CharacterState.JUMP ); 
				return;
			}
			
			var velXAbs:Number = Math.abs(node.motion.velocity.x);
			
			// if click is release (accelerate = false) & going fast enough, call SKID
			if ( node.motionControl.moveToTarget )		// check for skid
			{
				if ( fsmControl.check(CharacterState.DUCK) )
				{
					fsmControl.setState( CharacterState.DUCK );
					return;
				}
				else if( fsmControl.check(CharacterState.PUSH) )
				{
					fsmControl.setState( CharacterState.PUSH );
					return;
				}
			}
			else if ( fsmControl.hasType(CharacterState.SKID) )
			{
				if( velXAbs >= node.characterMotionControl.skidSpeed  )
				{
					fsmControl.setState( CharacterState.SKID );
					return;
				}
			}
			
			if ( velXAbs < charControl.runSpeed )		// check for walk
			{
				fsmControl.setState( CharacterState.WALK );
				return;
			}
			else if( velXAbs < charControl.walkSpeed )	// check for stand
			{
				fsmControl.setState( CharacterState.STAND ); 
				return;
			}
		}
	}
}