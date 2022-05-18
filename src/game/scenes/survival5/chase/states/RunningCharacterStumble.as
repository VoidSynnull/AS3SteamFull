package game.scenes.survival5.chase.states
{
	import engine.components.Spatial;
	
	import game.data.animation.entity.character.AttackRun;
	import game.util.SkinUtils;
	
	public class RunningCharacterStumble extends RunningCharacterState
	{
		private const SPEED_DECREASE:uint = 400;
		
		public function RunningCharacterStumble()
		{
			super.type = RunningCharacterState.STUMBLE;
		}
	
		override public function check():Boolean
		{
			return true;
		}
		
		/**
		 * Start the state
		 */
		override public function start():void
		{
//			node.looperCollider.isHit = false;
//			node.looperCollider.collisionType = null;
			
			node.charMotionControl.ignoreVelocityDirection = true;
			
			setAnim( AttackRun );
			super.updateStage = updateStumble;
			if( node.motionMaster.active )
			{
				// SLOWEST YOU CAN GO IS AN X VELOCITY OF -400
				node.motionMaster.velocity.x = ( node.motionMaster.velocity.x > -800 ) ? -400 : node.motionMaster.velocity .x + SPEED_DECREASE;
				if( _uiHead )
				{
					SkinUtils.setEyeStates( _uiHead, "casual_still", "forward" );
					Spatial( _uiHead.get( Spatial )).rotation = 15;
				}
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
		
		private function updateStumble():void
		{
			if( node.primary.current is AttackRun )
			{
				if( node.timeline.currentIndex == node.primary.current.data.frames.length - 2 )
				{
					node.fsmControl.setState( RunningCharacterState.RUN );
				}
			}
		}
	}
}