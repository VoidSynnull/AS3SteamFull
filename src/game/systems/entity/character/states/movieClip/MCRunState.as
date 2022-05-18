package game.systems.entity.character.states.movieClip 
{
	import game.components.animation.FSMControl;
	import game.components.entity.character.CharacterMotionControl;
	import game.components.entity.character.CharacterMovement;
	import game.systems.entity.EyeSystem;
	import game.systems.entity.character.states.CharacterState;
	import game.util.SkinUtils;
	
	public class MCRunState extends MCState 
	{
		public var runLabel:String = "run";
		
		public function MCRunState()
		{
			super.type = CharacterState.RUN;
		}
		
		override public function check():Boolean
		{
			return Math.abs(node.motion.velocity.x) >= node.charMotionControl.runSpeed;
		}
		
		/**
		 * Start the state
		 */
		override public function start():void
		{
			this.setLabel(runLabel);
			node.charMotionControl.ignoreVelocityDirection = false;
			node.charMotionControl.directionByVelocity = true;
			node.charMovement.state = CharacterMovement.GROUND;
			
			SkinUtils.setEyeStates( node.entity, EyeSystem.SQUINT, EyeSystem.FRONT, false );
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
				if( velXAbs >= node.charMotionControl.skidSpeed  )
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