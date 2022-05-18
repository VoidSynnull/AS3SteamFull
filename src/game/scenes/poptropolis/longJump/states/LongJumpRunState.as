package game.scenes.poptropolis.longJump.states 
{
	import game.components.animation.FSMControl;
	import game.components.entity.character.CharacterMotionControl;
	import game.data.animation.entity.character.poptropolis.LongJumpRun;
	import game.systems.entity.character.states.CharacterState;

	/**
	 * ...
	 * @author Bard McKinley
	 */
	public class LongJumpRunState extends CharacterState 
	{
		public function LongJumpRunState()
		{
			super.type = CharacterState.RUN;
		}
		
		/**
		 * Start the state
		 */
		override public function start():void
		{
			super.setAnim( LongJumpRun );
			node.timeline.stop();
			node.charMotionControl.ignoreVelocityDirection = false;
			node.charMotionControl.directionByVelocity = true;
		}
		
		/**
		 * Manage the state
		 */
		override public function update(time:Number):void
		{
			var charControl:CharacterMotionControl = node.charMotionControl;
			var fsmControl:FSMControl = node.fsmControl;
			
			// drun should only happen while input is active, once release shoudl jump
			if( node.motionControl.inputActive )
			{
				if ( !node.platformCollider.isHit )		// check for platform
				{
					fsmControl.setState( CharacterState.FALL );
					return;
				}
			}
			else
			{
				fsmControl.setState( CharacterState.JUMP ); 
				return;
			}
			
			// applyMotion
			applyMotion();
		}

		/**
		 * Method for moving character while on a surface
		 * @param	node
		 */
		public function applyMotion( ):void
		{
			// TODO :: adjust these values to work
			node.motion.maxVelocity.x = 600;
			node.motion.friction.x = 0;
			node.motion.acceleration.x = 40;
		}
	}
}