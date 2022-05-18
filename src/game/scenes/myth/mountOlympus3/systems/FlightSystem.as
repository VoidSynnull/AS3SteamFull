package game.scenes.myth.mountOlympus3.systems
{
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.motion.MotionTarget;
	import game.data.motion.time.FixedTimestep;
	import game.scenes.myth.mountOlympus3.components.FlightComponent;
	import game.scenes.myth.mountOlympus3.nodes.FlightNode;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	import game.util.GeomUtils;
	import game.util.PlatformUtils;
	
	/**
	 * system to manage flying mouse following motion of players
	 */
	public class FlightSystem extends GameSystem
	{
		
		public function FlightSystem()
		{			
			super( FlightNode, nodeUpdate );
			super.fixedTimestep = FixedTimestep.MOTION_TIME;
			super.linkedUpdate = FixedTimestep.MOTION_LINK;
			super._defaultPriority = SystemPriorities.move;
		}
		
		private function nodeUpdate( node:FlightNode, time:Number ):void
		{
			var flight:FlightComponent = node.flight;
			var motion:Motion = node.motion;
			
			if( flight.active )
			{
				if( flight.move && (node.motionControl.moveToTarget || PlatformUtils.isDesktop) )
				{
					var motionTarget:MotionTarget = node.motionTarget;
					var spatial:Spatial = node.spatial;
	
					motion.friction.x = motion.friction.y = 0;
					motion.maxVelocity.x = motion.maxVelocity.x = flight.speedMin + flight.speedMax ;
					
					var deltaDist:int = Math.sqrt( motionTarget.targetDeltaX * motionTarget.targetDeltaX + motionTarget.targetDeltaY * motionTarget.targetDeltaY )
					var radians:Number = GeomUtils.radiansBetween( motion.x, motion.y, motionTarget.targetX, motionTarget.targetY );
					
					var speed:Number;
					var speedFactor:Number;
					var distDiff:Number = deltaDist - flight.midDist;
					if( distDiff > 0 )
					{
						speedFactor = Math.min( distDiff/flight.maxDist, 1 ) * flight.spring;
						flight._velocity.x += Math.cos( radians ) * speedFactor;
						flight._velocity.y += Math.sin( radians ) * speedFactor;
						flight._velocity.x *= flight.dampener;
						flight._velocity.y *= flight.dampener;
	
						motion.x += flight._velocity.x;
						motion.y += flight._velocity.y;
						
						// mak face direction
						if( node.spatial.scaleX > 0 && flight._velocity.x > 0 || node.spatial.scaleX < 0 && flight._velocity.x < 0 )
						{
							node.spatial.scaleX *= -1;
						}
					}
				}

				//dampen
				var dampener:Number = .9;
				var velThreshold:Number = 20;
				var accelThreshold:Number = 100;
				
				if( Math.abs(motion.acceleration.x) > accelThreshold ){
					motion.acceleration.x *= dampener;
				}else{
					motion.acceleration.x = 0;
				}
				if( Math.abs(motion.acceleration.y) > accelThreshold ){
					motion.acceleration.y *= dampener;
				}else{
					motion.acceleration.y = 0;
				}
				
				if( Math.abs(motion.velocity.x) > velThreshold ){
					motion.velocity.x *= dampener;
				}else{
					motion.velocity.x = 0;
				}
				if( Math.abs(motion.velocity.y) > velThreshold ){
					motion.velocity.y *= dampener;
				}else{
					motion.velocity.y = 0;
				}
			}
		}
	}
}

