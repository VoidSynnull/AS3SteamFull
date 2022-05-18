package game.scenes.myth.mountOlympus3.playerStates
{
	import ash.core.Entity;
	
	import game.components.animation.FSMControl;
	import game.components.entity.Sleep;
	import game.data.animation.entity.character.Throw;
	import game.scenes.myth.mountOlympus3.components.Bolt;
	import game.util.GeomUtils;
	
	public class CloudAttack extends CloudCharacterState
	{
		public static const TYPE:String = "cloudAttack";
		private var _timer:Number = 0;
		private const MAX_TIME:Number = .5;
		
		public function CloudAttack()
		{
			super.type = CloudAttack.TYPE;
		}
		
		/**
		 * Start the state
		 */
		override public function start():void
		{
			var boltEntity:Entity = node.bolts.pool.request( Bolt.PLAYER_BOLT );
			if( boltEntity != null )	
			{
				// stop current motion
				node.flight.move = false;
				node.motion.zeroMotion();
				
				// start aniamtion
				super.setAnim( Throw, false );	// if already in throw, do we just restart?
				node.motionControl.lockInput = true;
				node.charMotionControl.ignoreVelocityDirection = true;
				
				// trigger bolt
				var bolt:Bolt = boltEntity.get( Bolt );	
				Sleep(boltEntity.get( Sleep )).sleeping = false;
				bolt.state = Bolt.SPAWN;
				bolt.rotation = GeomUtils.degreesBetween( node.motionTarget.targetX, node.motionTarget.targetY, node.spatial.x, node.spatial.y );
				
				// flip player scale based on click
				if( (node.motionTarget.targetX > node.spatial.x && node.spatial.scaleX > 0 ) || ( node.motionTarget.targetX < node.spatial.x && node.spatial.scaleX < 0 ) )
				{
					node.spatial.scaleX *= -1;
				}
				
				// restart timer
				_timer = 0;
			}
			else
			{
				// if bolt is not available, return to Stand
				trace( "CloudAttack :: No bolts available."); 
				node.fsmControl.setState( CloudStand.TYPE );
			}
		}
		
		/**
		 * Manage the state
		 */
		override public function update( time:Number ):void
		{
			var fsmControl:FSMControl = node.fsmControl;
		
			if ( fsmControl.check( CloudHurt.TYPE ) )			// check for hurt
			{
				fsmControl.setState( CloudHurt.TYPE );
				return;
			}
			
			/*
			// wait on animation
			if ( node.charMotionControl.animEnded )			// if animation has ended
			{
				node.motionControl.lockInput = false;
				node.charMotionControl.animEnded = false;
				node.fsmControl.setState( CloudStand.TYPE );	
			}
			*/

			_timer += time;
			if( _timer > MAX_TIME )
			{
				node.motionControl.lockInput = false;
				node.fsmControl.setState( CloudStand.TYPE );
				return;
			}
		}
	}
}