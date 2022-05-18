package game.scenes.myth.mountOlympus3.playerStates
{
	import game.components.animation.FSMControl;
	import game.data.animation.entity.character.Hurt;
	import game.util.MotionUtils;
	
	public class CloudHurt extends CloudCharacterState
	{
		public static const TYPE:String = "cloudHurt";
		
		public function CloudHurt()
		{
			super.type = CloudHurt.TYPE;
		}
		
		override public function check():Boolean
		{
			return node.hazardCollider.isHit;
		}
		
		override public function exit():void
		{
			node.hazardCollider.isHit = false;
		}
		
		/**
		 * Start the state
		 */
		override public function start():void
		{	
			if( !node.clouds.invincible )
			{
				node.charMotionControl.ignoreVelocityDirection = true;
				node.motionControl.lockInput = true;
				node.flight.move = false;

				node.clouds.killCloud( 1 );
				if( node.clouds.clouds.length > 0 )
				{
					super.setAnim( Hurt );
					super.updateStage = updateHurt;
				}
				else
				{
					super.setAnim( Hurt );
					node.timeline.labelHandlers.length = 0;
					node.motion.zeroMotion();
					node.motion.acceleration.y = MotionUtils.GRAVITY;
					node.motion.velocity.y = -500;
					node.flight.active = false;
					super.updateStage = updateDefeated;
				}
			}
			else
			{
				node.fsmControl.setState( CloudStand.TYPE );
				return
			}
		}
		
		/**
		 * Manage the state
		 */
		override public function update( time:Number ):void
		{
			super.updateStage();
		}
		
		private function updateHurt():void
		{
			var fsmControl:FSMControl = node.fsmControl;
			if( node.hazardCollider.interval <= 0 )	// if interval is up, return to swim
			{
				( Math.abs(node.motion.acceleration.x) < 10 && Math.abs(node.motion.acceleration.y) < 10 )
				{
					node.hazardCollider.interval = 0;
					node.motionControl.lockInput = false;
					node.fsmControl.setState( CloudStand.TYPE );
				}
			}
		}
		
		private function updateDefeated():void
		{
			// check for player reaching scene bounds, once there trigger end of game
			node.motion.acceleration.y = MotionUtils.GRAVITY;
			if( node.motionBounds.bottom )
			{
				node.entity.group.shellApi.triggerEvent( "lose_zeus" );
			}
		}
	}
}