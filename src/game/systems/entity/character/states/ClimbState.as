package game.systems.entity.character.states 
{
	
	import game.components.entity.character.CharacterMotionControl;
	import game.components.entity.character.CharacterMovement;
	import game.data.animation.entity.character.Climb;
	import game.data.animation.entity.character.ClimbDown;
	import game.systems.entity.EyeSystem;
	import game.util.SkinUtils;

	/**
	 * ...
	 * @author Bard McKinley
	 */
	public class ClimbState extends CharacterState
	{		
		private var _climbChange:Boolean = false;
		
		public function ClimbState()
		{
			super.type = CharacterState.CLIMB;
		}
		
		override public function check():Boolean 
		{
			return node.climbCollider.isHit;
		}
		
		/**
		 * Start the state
		 */
		override public function start():void 
		{
			super.setAnim( Climb );
			node.charMotionControl.ignoreVelocityDirection = false;
			node.charMovement.state = CharacterMovement.CLIMB;
			
			// clear any friction & velocity values
			node.motion.zeroMotion("x");
			node.motion.zeroMotion("y");
			node.motion.friction.x = 0;
			node.motion.y -= 5;	// move up a little to account for jumping to bottom of rope
			
			// TODO :: Need a way to ignore platform hits
			
			// if spinning, set speed and flag to end
			if ( node.charMotionControl.spinning )
			{
				node.charMotionControl.spinSpeed = node.charMotionControl.spinLandRotation;
				node.charMotionControl.spinEnd = true;
			}
		}
		
		/**
		 * Manage the state
		 */
		override public function update( time:Number ):void 
		{
			var stateControl:CharacterMotionControl = node.charMotionControl;
			
			// check for hazard collision
			if ( node.fsmControl.check(CharacterState.HURT) )				
			{
				node.fsmControl.setState( CharacterState.HURT );
				return;
			}
			else if ( node.climbCollider.isHit )
			{
				// update climb direction & animation based on motion
				if ( node.motion.velocity.y < 0 && node.motion.acceleration.y >= 0 )
				{
					stateControl.climbingUp = true;
					super.setAnim( Climb );
				}
				else if ( node.motion.velocity.y > 0 )
				{
					stateControl.climbingUp = false;
					super.setAnim( ClimbDown );
				}
				else 
				{
					stateControl.climbingUp = false;	// don't change animation
					// TODO :: if mouse click out of climb ranges, change eyes to tracking
					//SkinUtils.setEyeStates( node.entity, EyeSystem.BLINK );
				}
			}
			else
			{
				node.fsmControl.setState( CharacterState.FALL );
			}
		}
	}
}