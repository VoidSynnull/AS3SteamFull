package game.scenes.survival5.chase.states
{
	import game.data.animation.entity.character.DuckSpin;

	public class RunningCharacterRoll extends RunningCharacterState
	{
		private const ENDING_LABEL:String = "ending";
		
		public function RunningCharacterRoll()
		{
			super.type = RunningCharacterState.ROLL;
		}
		
		/**
		 * Start the state
		 */
		override public function start():void
		{			
			node.charMotionControl.ignoreVelocityDirection = false;
			node.charMotionControl.spinning = true;
			node.charMotionControl.spinCount = 1;							
			node.charMotionControl.spinSpeed = node.charMotionControl.duckRotation;	// set spin speed
			
			node.motion.friction.x = node.charMotionControl.duckFriction;
			
			setAnim( DuckSpin );
			super.updateStage = this.updateSpin;
		}
		
		override public function check():Boolean
		{
			switch( node.looperCollider.collisionType )
			{
				case "tree":
					node.looperCollider.isHit = false;
					return false;

				default:
					node.fsmControl.setState( RunningCharacterState.STUMBLE );
					return true;
			}
		}
		
		/**
		 * Manage the state
		 */
		override public function update( time:Number ):void
		{
			super.update( time );
			super.updateStage();
		}
		
		private function updateSpin():void
		{
			if ( node.charMotionControl.spinStopped )
			{	
				returnToRun();
				return;
			}
		}
		
		private function returnToRun():void
		{
			node.fsmControl.setState( RunningCharacterState.RUN );
			node.charMotionControl.animEnded = false;
			node.motion.rotationVelocity = 0;
			node.motion.rotation = 0;
		}
	}
}