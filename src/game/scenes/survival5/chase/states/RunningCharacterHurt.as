package game.scenes.survival5.chase.states
{
	import flash.geom.Point;
	
	import game.data.animation.entity.character.Hurt;
	import game.scenes.reality2.cheetahRun.CheetahRun;
	import game.util.MotionUtils;
	import game.util.SkinUtils;

	public class RunningCharacterHurt extends RunningCharacterState
	{
		private const MODIFIER:uint = 2;
		private const STOP_LABEL:String = "stop";
		
		public function RunningCharacterHurt()
		{
			super.type = RunningCharacterState.HURT;
		}
		
		override public function check():Boolean
		{
			return false;
		}
		
		/**
		 * Start the state
		 */
		override public function start():void
		{
	//		node.looperCollider.isHit = false;
	//		node.looperCollider.collisionType = null;

			node.charMotionControl.ignoreVelocityDirection = true;
			node.motionControl.lockInput = true;
			node.motionControl.moveToTarget = false;
			
			node.motion.velocity.y = -300;
			node.motion.acceleration = new Point( 0, MotionUtils.GRAVITY );
			
			setAnim( Hurt );
			super.updateStage = updateHurt;
			if( _uiHead && node.motionMaster.active )
			{
				SkinUtils.setEyeStates( _uiHead, "closed" );
			}
			if(_isReality)
				CheetahRun(node.owningGroup.group.shellApi.currentScene).numJumps = 0;
		}
		
		/**
		 * Manage the state
		 */
		override public function update( time:Number ):void
		{
			super.update( time );
			super.updateStage();
		}
		
		private function updateHurt():void
		{
			if ( node.platformCollider.isHit )
			{
				node.fsmControl.setState( RunningCharacterState.STUMBLE );
			}
		}
	}
}