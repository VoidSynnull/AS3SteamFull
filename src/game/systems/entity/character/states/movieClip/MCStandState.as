package game.systems.entity.character.states.movieClip
{
	import game.components.entity.character.CharacterMovement;
	import game.systems.entity.character.states.CharacterState;
	import game.systems.entity.character.states.IdleState;
	
	public class MCStandState extends MCState
	{
		protected var _idleCounter:int;
		public var standLabel:String = "stand";
		
		public function MCStandState()
		{
			super.type = CharacterState.STAND;
		}
		
		/**
		 * Start the state
		 */
		override public function start():void
		{
			var idleState:IdleState = node.fsmControl.getState(CharacterState.IDLE) as IdleState;
			if( idleState )
			{
				_idleCounter = idleState.getDelay(); 
			}
			
			this.setLabel(this.standLabel);
			//SkinUtils.setSkinPart( node.entity, SkinUtils.MOUTH, SkinPart.DEFAULT_VALUE );	// TODO :: Bit of a hack to resolve annoying mouth issue
			//set mouth to default
			node.charMotionControl.ignoreVelocityDirection = false;
			node.charMovement.state = CharacterMovement.GROUND;
		}
		
		/**
		 * Manage the state
		 */
		override public function update( time:Number ):void
		{
			//var charControl:CharacterMotionControl = node.charMotionControl;
			
			if ( node.fsmControl.check(CharacterState.HURT) )			// check for platform collision
			{
				node.fsmControl.setState( CharacterState.HURT );
				return;
			}
			else if ( node.fsmControl.check(CharacterState.FALL) )		// check for platform collision
			{
				node.fsmControl.setState( CharacterState.FALL );
				return;
			}
			else if ( node.motionControl.moveToTarget )	// check press & velocity
			{
				if ( node.fsmControl.check(CharacterState.JUMP) )		// check for jump
				{
					node.motion.zeroMotion( "x" );
					node.fsmControl.setState( CharacterState.JUMP ); 
					return;
				}
				else if ( node.fsmControl.check(CharacterState.DUCK) )	// check for jump
				{
					node.fsmControl.setState( CharacterState.DUCK ); 
					return;
				}
				else if( node.fsmControl.check(CharacterState.PUSH) )
				{
					node.fsmControl.setState( CharacterState.PUSH );
					return;
				}
				else if ( node.fsmControl.check(CharacterState.WALK) )
				{
					node.fsmControl.setState(CharacterState.WALK);
					return;
				}
			}
			else if ( node.fsmControl.hasType(CharacterState.IDLE) )
			{
				_idleCounter--;
				if (_idleCounter <= 0) 
				{
					node.fsmControl.setState(CharacterState.IDLE);
				}
			}
		}
	}
}