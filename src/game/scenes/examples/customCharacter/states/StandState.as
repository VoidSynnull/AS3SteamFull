package game.scenes.examples.customCharacter.states
{
	import game.components.entity.character.CharacterMotionControl;
	import game.components.entity.character.CharacterMovement;
	
	public class StandState extends CustomCharacterState
	{
		public function StandState()
		{
			super.type = CustomCharacterState.STAND;
		}
		
		/**
		 * Start the state
		 */
		override public function start():void
		{
			/*
			var idleState:IdleState = node.fsmControl.getState(CustomCharacterState.IDLE) as IdleState;
			if( idleState )
			{
				_idleCounter = idleState.getDelay(); 
			}
			*/
			super.setAnim(super.animationId);
			//SkinUtils.setSkinPart( node.entity, SkinUtils.MOUTH, SkinPart.DEFAULT_VALUE );	// TODO :: Bit of a hack to resolve annoying mouth issue
			//set mouth to default
			node.characterMotionControl.ignoreVelocityDirection = false;
			node.characterMovement.state = CharacterMovement.GROUND;
		}
		
		/**
		 * Manage the state
		 */
		override public function update( time:Number ):void
		{
			var charControl:CharacterMotionControl = node.characterMotionControl;
			
			if ( node.fsmControl.check(CustomCharacterState.HURT) )			// check for platform collision
			{
				node.fsmControl.setState( CustomCharacterState.HURT );
				return;
			}
			else if ( node.fsmControl.check(CustomCharacterState.FALL) )		// check for platform collision
			{
				node.fsmControl.setState( CustomCharacterState.FALL );
				return;
			}
			else if ( node.motionControl.moveToTarget )	// check press & velocity
			{
				if ( node.fsmControl.check(CustomCharacterState.JUMP) )		// check for jump
				{
					node.motion.zeroMotion( "x" );
					node.fsmControl.setState( CustomCharacterState.JUMP ); 
					return;
				}
				else if ( node.fsmControl.check(CustomCharacterState.DUCK) )	// check for jump
				{
					node.fsmControl.setState( CustomCharacterState.DUCK ); 
					return;
				}
				else if( node.fsmControl.check(CustomCharacterState.PUSH) )
				{
					node.fsmControl.setState( CustomCharacterState.PUSH );
					return;
				}
				else if ( node.fsmControl.check(CustomCharacterState.WALK) )
				{
					node.fsmControl.setState(CustomCharacterState.WALK);
					return;
				}
			}
			/*
			else if ( node.fsmControl.hasType(CustomCharacterState.IDLE) )
			{
				_idleCounter--;
				if (_idleCounter <= 0) 
				{
					node.fsmControl.setState(CustomCharacterState.IDLE);
				}
			}
			*/
		}
		
		//private var _idleCounter:Number;
	}
}


