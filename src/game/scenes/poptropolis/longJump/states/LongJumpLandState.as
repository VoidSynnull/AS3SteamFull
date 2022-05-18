package game.scenes.poptropolis.longJump.states 
{
	import game.components.entity.character.CharacterMotionControl;
	import game.systems.entity.character.states.CharacterState;

	/**
	 * ...
	 * @author Bard McKinley
	 */
	public class LongJumpLandState extends CharacterState 
	{
		private var _transitionTo:String = "";
		
		public function LongJumpLandState()
		{
			super.type = CharacterState.LAND;
		}
		
		/**
		 * Start the state
		 */
		override public function start():void
		{
			var charControl:CharacterMotionControl = node.charMotionControl;
			charControl.ignoreVelocityDirection = true;

			node.motion.friction.x = charControl.frictionStop;
			setAnim( LongJumpLandState, true );
		}
		
		/**
		 * Manage the state
		 */
		override public function update( time:Number ):void 
		{
			if ( node.charMotionControl.animEnded )	// if animation has ended
			{
				node.charMotionControl.animEnded = false;
				node.fsmControl.setState( CharacterState.STAND );	// TODO :: might want to direct to something else?
				return;	
			}
		}
	}
}