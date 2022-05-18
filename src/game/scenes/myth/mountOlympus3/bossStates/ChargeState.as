package game.scenes.myth.mountOlympus3.bossStates
{
	import flash.geom.Point;
	
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.scenes.myth.mountOlympus3.playerStates.CloudHurt;
	import game.util.GeomUtils;
	
	public class ChargeState extends ZeusState
	{
		// class variables
		private var _goal:Point;
		private var _stateTimer:Number = 0;		// in seconds
		private const START_DELAY:Number = 2;			// in seconds
		private const COMPLETE_DELAY:Number = 1;			// in seconds
		private const CHARGE_PAST_DURATION:Number = 1;			// in seconds
		private var _targetPoint:Point = new Point();
		private var _reachedPoint:Boolean = false;
		public var subState:String = PREP;
		
		
		// labels
		private static const CHARGE:String =		"charge";
		private static const CHARGING:String =		"charging";
		private static const END:String =			"end";
		private static const FINISHED:String =		"finished";
		private static const HIT:String =			"hit";
		private static const PREP:String =			"prep";
		private static const STOP:String =			"stop";
		
		public function ChargeState()
		{
			type = CHARGE;
		}
		
		override public function start():void
		{
			setInvincible();
			node.motion.maxVelocity.x = node.motion.maxVelocity.y = Infinity;
			_stateTimer = 0;
			super.start();
		}

		override public function update( time:Number ):void
		{
			var rotationTo:Number;
			var distance:Number;
			var targetSpatial:Spatial = node.targetSpatial.target;
			var spatial:Spatial = node.spatial;
			var motion:Motion = node.motion;

			switch( subState )
			{
				case PREP:
					_stateTimer += time;
					if( _stateTimer > START_DELAY )
					{
						subState = CHARGE;
						_stateTimer = 0;
					}
					break;
					
				case CHARGE:	
					
					subState = CHARGING;
					node.timeline.stop();

					_targetPoint.x = targetSpatial.x;
					_targetPoint.y = targetSpatial.y;
					_reachedPoint = false;
					rotationTo = GeomUtils.radiansBetween( spatial.x, spatial.y, _targetPoint.x, _targetPoint.y );
					motion.velocity.x = 2000 * Math.cos( rotationTo );
					motion.velocity.y = 2000 * Math.sin( rotationTo );
					trace( "start charging." )

					if((( targetSpatial.x > spatial.x ) && spatial.scaleX > 0 ) || ( targetSpatial.x < spatial.x ) && spatial.scaleX < 0 )
					{
						spatial.scaleX *= -1;
					}
					break;
					
				case CHARGING:
					
					// TODO :: this check shoudl probably be happening in fixedtime. - bard
					if( GeomUtils.spatialDistance( targetSpatial, spatial ) < 100 )
					{	
						node.audio.playCurrentAction( HIT );
						
						playerNode.hazardCollider.isHit = true;
						playerNode.hazardCollider.coolDown = 1;
						playerNode.hazardCollider.interval = .2;
	
						rotationTo = GeomUtils.radiansBetween( spatial.x, spatial.y, targetSpatial.x, targetSpatial.y );
						playerNode.motion.acceleration.x = Math.cos( rotationTo ) * 10000;
						playerNode.motion.acceleration.y = Math.sin( rotationTo ) * 10000;
						playerNode.fsmControl.setState( CloudHurt.TYPE );
	
						motion.velocity.x = 0;
						motion.velocity.y = 0;
						targetSpatial.rotation = 0;
						
						_stateTimer = 0;
						subState = END;
						break;
					}
					
					// if past
					if( !_reachedPoint )
					{
						_reachedPoint = GeomUtils.distSquared( _targetPoint.x, _targetPoint.y, spatial.x, spatial.y ) < 300;
					}
					else
					{
						_stateTimer += time;
						( _stateTimer > CHARGE_PAST_DURATION )
						{
							subState = FINISHED;
							node.motion.zeroMotion();
							break;
						}
					}
					
					if(( spatial.x < 30 || spatial.x > 2700  || spatial.y > 1600 || spatial.y < 30 ))
					{
						subState = FINISHED;
						node.motion.zeroMotion();
					}
					
					break;
				
				case END:
					_stateTimer += time;
					if( _stateTimer > COMPLETE_DELAY )
					{
						subState = FINISHED;
					}
					break;
					
				case FINISHED:
					_stateTimer = 0;
					setInvincible( false );
					subState = PREP;
						
					ZeusState(node.fsmControl.state).moveToNext();
					
					break;
			}
		}
	}
}