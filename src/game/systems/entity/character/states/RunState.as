package game.systems.entity.character.states 
{
	import game.components.animation.FSMControl;
	import game.components.entity.character.Character;
	import game.components.entity.character.CharacterMotionControl;
	import game.components.entity.character.CharacterMovement;
	import game.data.animation.entity.character.Run;
	import game.data.character.CharacterData;
	import game.systems.entity.EyeSystem;
	import game.util.SkinUtils;

	/**
	 * ...
	 * @author Bard McKinley
	 */
	public class RunState extends CharacterState 
	{
		public var runAnim:Class = Run;
		private var isPet:Boolean = false;
		private var runSpeed:Number = 0;
		
		public function RunState()
		{
			super.type = CharacterState.RUN;
		}
		
		override public function check():Boolean
		{
			// get pet status and run speed
			getSpeed();
			
			return Math.abs(node.motion.velocity.x) >= runSpeed;
		}
		
		private function getSpeed():void
		{
			if (runSpeed == 0)
			{
				runSpeed = node.charMotionControl.runSpeed;
				isPet = (Character(node.entity.get(Character)).currentCharData.variant == CharacterData.VARIANT_PET_BABYQUAD);
				if (isPet)
				{
					runSpeed = node.charMotionControl.petRunSpeed;
				}
			}
		}
		
		/**
		 * Start the state
		 */
		override public function start():void
		{
			super.setAnim(  runAnim );
			node.charMotionControl.ignoreVelocityDirection = false;
			node.charMotionControl.directionByVelocity = true;
			node.charMovement.state = CharacterMovement.GROUND;
			
			// get pet status and run speed
			getSpeed();
			
			// don't squint eyes if pet
			if (!isPet)
			{
				SkinUtils.setEyeStates( node.entity, EyeSystem.SQUINT, EyeSystem.FRONT, false );
			}
		}
		
		/**
		 * Manage the state
		 */
		override public function update( time:Number ):void
		{
			var charControl:CharacterMotionControl = node.charMotionControl;
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
			if ((!isPet) && ( node.motionControl.moveToTarget ))		// check for skid
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
				if (isPet)
				{
					// if player is skidding, then skid pet
					if (fsmControl.shellApi.player.get(FSMControl).state.type == CharacterState.SKID)
					{
						fsmControl.setState( CharacterState.SKID );
					}
				}
				else if ((!isPet) && ( velXAbs >= node.charMotionControl.skidSpeed  ))
				{
					fsmControl.setState( CharacterState.SKID );
					return;
				}
			}

			if ( velXAbs < runSpeed )		// check for walk
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