package game.systems.entity.character.states.touch 
{
	import game.components.entity.character.CharacterMotionControl;
	import game.components.entity.character.CharacterMovement;
	import game.systems.entity.character.states.CharacterState;
	import game.systems.entity.character.states.StandState;


	public class StandState extends game.systems.entity.character.states.StandState 
	{
		private var _clickCounter:Number = 0;

		public function StandState()
		{
			super();
		}
		
		override public function start():void
		{
			super.start();
			node.charMovement.state = CharacterMovement.NONE; // don't apply ground movement (don't want to move while we wait for click delay)
			_clickCounter = 0;
		}
		
		/**
		 * Manage the state
		 */
		override public function update( time:Number ):void
		{
			var charControl:CharacterMotionControl = node.charMotionControl;
			charControl.waitingForRelease = false;

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
			else if ( node.motionControl.moveToTarget )		// input is active & outside of input deadzone, or is being forced to target
			{
				if( node.motionControl.forceTarget )		// if force target don't wait on click
				{
					if ( node.fsmControl.check(CharacterState.JUMP) )		// check for jump
					{		
						node.fsmControl.setState( CharacterState.JUMP ); 
						return;
					}
					else if ( node.fsmControl.check(CharacterState.DUCK) )	// check for duck
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
					node.charMovement.state = CharacterMovement.GROUND;
				}
				else								
				{
					_clickCounter += time;	// check counter to determine is if input was is a 'click'
					charControl.waitingForRelease = true;
					node.charMovement.state = CharacterMovement.NONE;
					
					// note may want to compound velocity while moveToTarget is true
					// if counter passes click duration treat normally
					if( _clickCounter >= CLICK_DELAY )	
					{
						node.charMotionControl.waitingForRelease = false;
						
						// check for standard jump
						if ( node.fsmControl.check(CharacterState.JUMP) ) 		
						{		
							node.motion.zeroMotion( "x" );
							node.fsmControl.setState( CharacterState.JUMP ); 
							return;
						}
						else if ( node.fsmControl.check(CharacterState.DUCK) )
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
						
						node.charMovement.state = CharacterMovement.GROUND;
					}
				}
			}
			else 
			{
				// if counter is still in range of click delay
				if( _clickCounter > 0 && _clickCounter < CLICK_DELAY )
				{
					_clickCounter = 0;
					
					// input must be inactive(released) and outside of inputDeadzone for jump assist
					if( !node.motionControl.inputActive && !checkJumpTargetDeadzone() )
					{
						if ( node.fsmControl.hasType(CharacterState.JUMP) )
						{		
							node.motion.zeroMotion( "x" );
							node.charMotionControl.jumpTargetTrigger = true;	// makes CharacterJumpAssistSystem active
							node.fsmControl.setState( CharacterState.JUMP ); 
							return;
						}
					}
					else
					{
						node.charMovement.state = CharacterMovement.GROUND;
					}
				}
				else
				{
					node.charMovement.state = CharacterMovement.GROUND_FRICTION;	// only apply ground friction, not ground movement (don't want to move while we wait for click delay)
				}
				
				
				/*
				if ( node.fsmControl.hasType(CharacterState.IDLE) )
				{
					_idleCounter -= time;
					if (_idleCounter <= 0) 
					{
						node.fsmControl.setState(CharacterState.IDLE);
					}
				}
				*/
			}
		}
		
		/**
		 * Determine if input is within deadzone of jump target.
		 * @param	node
		 * @return
		 */
		private function checkJumpTargetDeadzone():Boolean
		{
			if( Math.abs(node.motionTarget.targetDeltaX) < node.charMotionControl.inputDeadzoneX * 4 )
			{
				if( -node.motionTarget.targetDeltaY < -node.edge.rectangle.top/2 && node.motionTarget.targetDeltaY < (node.edge.rectangle.bottom * 2) )	// use characters edge to determine y deadzone
				{
					return true;
				}
			}
			return false;
		}
	}
}