package game.systems.entity.character.states
{
	import game.components.motion.MotionTarget;
	import game.data.animation.entity.character.StandNinja;
	import game.util.CharUtils;

	public class FlyingPlatformRide extends FlyingPlatformState
	{
		public function FlyingPlatformRide()
		{
			super.type = FlyingPlatformState.RIDE;
		}
		
		/**
		 * Start the state
		 */
		override public function start():void
		{
			node.looperCollider.isHit = false;
			node.looperCollider.collisionType = null;
			
			setAnim( StandNinja );
			super.updateStage = updateRide;
		}
		
		override public function check():Boolean
		{
			node.fsmControl.setState( FlyingPlatformState.HURT );
			
			return true;
		}
		
		/**
		 * Manage the state
		 */
		override public function update( time:Number ):void
		{
			super.update( time );
			super.updateStage();
		}
		
		private function updateRide():void
		{
			if( node.motionControl.moveToTarget )
			{
				var motionTarget:MotionTarget = node.entity.get( MotionTarget );
				CharUtils.setDirection( node.entity, motionTarget.targetX > node.spatial.x );
			}
		}
	}
}