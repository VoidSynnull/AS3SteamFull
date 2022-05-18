package game.systems.entity.character.states.movieClip
{
	import game.components.animation.FSMControl;
	import game.components.entity.character.CharacterMovement;
	import game.systems.entity.character.states.CharacterState;
	import game.util.CharUtils;
	
	public class MCWalkState extends MCState
	{
		public var walkLabel:String = "walk";
		
		public function MCWalkState()
		{
			super.type = CharacterState.WALK;
		}
		
		override public function check():Boolean
		{
			return Math.abs(node.motion.velocity.x) >= node.charMotionControl.walkSpeed;
		}
		
		/**
		 * Start the state
		 */
		override public function start():void 
		{
			this.setLabel(walkLabel);
			node.charMotionControl.ignoreVelocityDirection = false;
			node.charMotionControl.directionByVelocity = true;
			node.charMovement.state = CharacterMovement.GROUND;
			
			//SkinUtils.setSkinPart(node.entity, SkinUtils.EYE_STATE, "squint", false);
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
				return;
			}
			else if ( fsmControl.check(CharacterState.FALL) )		// check for platform collision		
			{
				fsmControl.setState( CharacterState.FALL );
				return;
			}
			else if ( node.motionControl.moveToTarget || !node.motionControl.inputActive )					// if click down
			{
				if ( fsmControl.check(CharacterState.JUMP) )			// check for jump
				{
					fsmControl.setState( CharacterState.JUMP ); 
					return;
				}
				else if ( fsmControl.check(CharacterState.DUCK) )		// check for jump
				{
					fsmControl.setState( CharacterState.DUCK ); 
					return;
				}
				else if( fsmControl.check(CharacterState.PUSH) )
				{
					fsmControl.setState( CharacterState.PUSH );
					return;
				}
				else if ( fsmControl.check(CharacterState.RUN) )		// check run
				{
					// TODO :: do we need to wait for right frame to transition to run?
					// if so would check for loop flag in animation, could also try to match frames
					fsmControl.setState( CharacterState.RUN ); 
					return;
				}
			}
			else if ( fsmControl.hasType(CharacterState.SKID) )
			{
				// Check if the player should be sliding when the user is no longer clicking down the mouse
				if( CharUtils.getFriction(node.entity) != null )
				{
					fsmControl.setState(CharacterState.SKID);
				}
			}
			
			if( Math.abs(node.motion.velocity.x) < node.charMotionControl.walkSpeed )	// check stand
			{
				fsmControl.setState( CharacterState.STAND ); 
				return;
			}
		}
	}
}