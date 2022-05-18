package game.systems.hit
{
	import flash.geom.Point;
	
	import ash.core.Engine;
	import ash.core.NodeList;
	import ash.core.System;
	
	import engine.components.Display;
	
	import game.data.motion.time.FixedTimestep;
	import game.data.scene.hit.MovingHitData;
	import game.nodes.hit.MovingHitNode;
	import game.systems.SystemPriorities;

	public class MovingHitSystem extends System
	{
		private var _platforms : NodeList;

		public function MovingHitSystem()
		{
			super.fixedTimestep = FixedTimestep.MOTION_TIME;
			super.linkedUpdate = FixedTimestep.MOTION_LINK;
			super._defaultPriority = SystemPriorities.move;
		}

		override public function addToEngine( game : Engine ) : void
		{
			_platforms = game.getNodeList( MovingHitNode );
		}
		
		override public function update( time : Number ) : void
		{
			var platform:MovingHitNode;
			var platformDisplay:Display;
			var currentPoint:Point;
			var data:MovingHitData;

			for (platform = _platforms.head; platform; platform = platform.next)
			{				
				data = platform.data;
				
				if(data != null)
				{
					if(data.points != null)
					{
						if (data.points.length > 0 && !data.pause)
						{
							currentPoint = data.points[data.pointIndex];
							
							if ((platform.motion.velocity.x > 0 && platform.motion.x >= currentPoint.x) ||
							    (platform.motion.velocity.x < 0 && platform.motion.x < currentPoint.x))
							{
								platform.motion.velocity.x = 0;
								platform.motion.x = currentPoint.x;
							}
		
							if ((platform.motion.velocity.y > 0 && platform.motion.y >= currentPoint.y) ||
							    (platform.motion.velocity.y < 0 && platform.motion.y < currentPoint.y))
							{
								platform.motion.velocity.y = 0;
								platform.motion.y = currentPoint.y;
							}
							
							if (platform.motion.velocity.length < .1)
							{
								if (data.pointIndex < data.points.length - 1)
								{
									data.pointIndex++;
									data.reachedPoint.dispatch();
								}
								else if(data.loop)
								{
									data.pointIndex = 0;
									if(data.teleportToStart)
									{
										currentPoint = data.points[data.pointIndex];
										platform.motion.x = currentPoint.x;
										platform.motion.y = currentPoint.y;
										data.pointIndex++;
									}
								}
								else
								{
									data.reachedFinalPoint.dispatch();
									break;
								}
								
								currentPoint = data.points[data.pointIndex];
								
								// set moving hit velocity based on distance from next point along x and y axis.
								var deltaX:Number = currentPoint.x - platform.motion.x;
								var deltaY:Number = currentPoint.y - platform.motion.y;
								var angle:Number = Math.atan2(deltaY, deltaX);
								
								platform.motion.velocity.x = Math.cos(angle) * data.velocity;
								platform.motion.velocity.y = Math.sin(angle) * data.velocity;
							}
						}
					}
				}
			}
		}

		override public function removeFromEngine( game : Engine ) : void
		{
			var platform:MovingHitNode;
			
			for (platform = _platforms.head; platform; platform = platform.next)
			{
				platform.data.reachedFinalPoint.removeAll();
				platform.data.reachedPoint.removeAll();
			}
			
			game.releaseNodeList( MovingHitNode );
			_platforms = null;
		}
	}
}
