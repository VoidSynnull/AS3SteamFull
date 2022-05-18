package game.systems.motion
{
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	import ash.core.NodeList;
	
	import engine.components.Spatial;
	
	import game.components.motion.Swarmer;
	import game.data.motion.time.FixedTimestep;
	import game.nodes.motion.SwarmNode;
	import game.util.GeomUtils;
	import game.util.PerformanceUtils;
	import game.systems.GameSystem;

	public class SwarmSystem extends GameSystem
	{
		public static const DEGRAD:Number = Math.PI/180;
		public static const RADDEG:Number = 180 / Math.PI;
		public static const TOOCLOSE:Number = 10000;
		
		public function SwarmSystem()
		{
			super(SwarmNode, updateNode);
			
			if(PerformanceUtils.qualityLevel > PerformanceUtils.QUALITY_MEDIUM)
				super.fixedTimestep = FixedTimestep.MOTION_TIME;
			else
				super.fixedTimestep = 1/10;
		}
		
		private function updateNode(currentNode:SwarmNode, time:Number):void
		{
			var swarmer:Swarmer = currentNode.swarmer;				
			var steeringForce:Point = new Point();
			var sepForce:Point = separation(currentNode, nodeList);
			var alignForce:Point = alignment(nodeList);
			var cohesionForce:Point = cohesion(currentNode, nodeList);
			
			steeringForce = steeringForce.add(multiply(wander(currentNode), swarmer.wanderWeight));
			steeringForce = steeringForce.add(multiply(alignForce, swarmer.alignWeight));
			steeringForce = steeringForce.add(multiply(sepForce, swarmer.separationWeight));
			steeringForce = steeringForce.add(multiply(cohesionForce, swarmer.cohesionWeight));
			steeringForce = steeringForce.add(multiply(tether(currentNode, group.shellApi.currentScene.sceneData.bounds), swarmer.tetherWeight));
			
			if(swarmer.obstacles != null)
			{
				for each(var obstacle:Entity in swarmer.obstacles)
				{
					var avoidance:Point = avoid(currentNode, obstacle.get(Spatial), 150);
					if(avoidance != null)
						steeringForce = avoidance;
				}
			}
			else if(swarmer.followTarget != null)
			{
				steeringForce = steeringForce.add(multiply(seek(currentNode, new Point(swarmer.followTarget.target.x, swarmer.followTarget.target.y)), swarmer.followWeight));
			}
		
			var mag:Number = steeringForce.length;
			if(steeringForce.length > currentNode.motion.maxVelocity.x)
			{
				steeringForce.x /= mag;
				steeringForce.y /= mag;
				steeringForce = multiply(steeringForce, currentNode.motion.maxVelocity.x);
			}
			
			currentNode.motion.acceleration = steeringForce;			
			currentNode.spatial.rotation = Math.atan2(-currentNode.motion.velocity.y, -currentNode.motion.velocity.x) * RADDEG;
		}
		
		private function alignment(swarmers:NodeList):Point
		{
			var desVel:Point = new Point();
			var count:int = 0;

			for(var node:SwarmNode = swarmers.head; node; node = node.next)
			{
				desVel.x += node.motion.velocity.x;
				desVel.y += node.motion.velocity.y;
				count++;
			}
			
			if(count == 0)
				return desVel;
			
			desVel.x /= count;
			desVel.y /= count;
			return desVel;
		}
		
		private function separation(currentNode:SwarmNode, swarmers:NodeList):Point
		{
			var desVel:Point = new Point();
			var closer:Number = 10000000;
			
			for(var node:SwarmNode = swarmers.head; node; node = node.next)
			{
				if(currentNode != node)
				{
					var dist:Number = GeomUtils.distSquared(currentNode.spatial.x, currentNode.spatial.y, node.spatial.x, node.spatial.y);
					if( dist < TOOCLOSE && dist < closer)
					{
						desVel = flee(currentNode, new Point(node.spatial.x, node.spatial.y));
						closer = dist;
					}
				}
			}		
			return desVel;
		}
		
		private function cohesion(currentNode:SwarmNode, swarmers:NodeList):Point
		{
			var desVel:Point = new Point();
			var count:int = 0;
			
			for(var node:SwarmNode = swarmers.head; node; node = node.next)
			{
				desVel.x += node.spatial.x;
				desVel.y += node.spatial.y;
				count++;
			}
			
			if(count == 0)
				return desVel;
			
			desVel.x /= count;
			desVel.y /= count;	
			
			return seek(currentNode, desVel);			
		}
		
		private function wander(currentNode:SwarmNode):Point
		{
			var swarmer:Swarmer = currentNode.swarmer;
			
			swarmer.wanderAngle += (Math.random() * swarmer.wanderMax*2 - swarmer.wanderMax);
			if(swarmer.wanderAngle > 360) swarmer.wanderAngle = 0;
			if(swarmer.wanderAngle < -360) swarmer.wanderAngle = 0;
			
			var redDot:Point = new Point();
			redDot.x = currentNode.spatial.x + (currentNode.motion.velocity.x * swarmer.wanderDist);
			redDot.y = currentNode.spatial.y + (currentNode.motion.velocity.y * swarmer.wanderDist);
			
			var offset:Point = new Point();
			offset.x = currentNode.motion.velocity.x * swarmer.wanderRadius;
			offset.y = currentNode.motion.velocity.y * swarmer.wanderRadius;
			
			var rad:Number = swarmer.wanderAngle * DEGRAD;
			var cos:Number = Math.cos(rad);
			var sin:Number = Math.sin(rad);
			offset.x = offset.x * cos - offset.y * sin;
			offset.y = offset.y * cos - offset.x * sin;
			
			redDot = redDot.add(offset);
			return seek(currentNode, redDot);
		}
		
		private function avoid(current:SwarmNode, obstacle:Spatial, safeDistance:Number):Point
		{
			var desVel:Point = new Point();
			var obstaclePos:Point = new Point(obstacle.x, obstacle.y);
			var obstacleRadius:Number = Math.sqrt((obstacle.width * obstacle.width) + (obstacle.height * obstacle.height));
			var vectorToObstacleCenter:Point = obstaclePos.subtract(new Point(current.spatial.x, current.spatial.y));
			
			// if the magnitude of vector to center minus the radius is greater than the safe distance return null
			if(vectorToObstacleCenter.length - obstacleRadius > safeDistance)
				return null;
			
			var right:Point = new Point(-current.motion.velocity.y, current.motion.velocity.x);
			var rightDotVTOC:Number = dot(vectorToObstacleCenter, right);
			var myRadius:Number = Math.sqrt((current.spatial.width * current.spatial.width) + (current.spatial.height * current.spatial.height));
			// if sum of radii < dot of vectorToCenter with right, return null
			if((obstacleRadius + myRadius) < rightDotVTOC)
				return null;
			
			//desired velocity is to the right or left depending on the sign of the dot of right and vtoc
			if(rightDotVTOC < 0)
			{
				desVel.x = right.x * current.motion.maxVelocity.x;
				desVel.y = right.y * current.motion.maxVelocity.y;
			}
			else
			{
				desVel.x = right.x * -current.motion.maxVelocity.x;
				desVel.y = right.y * -current.motion.maxVelocity.y;
			}
			
			return desVel.subtract(current.motion.velocity);
		}
		
		private function tether(current:SwarmNode, sceneBounds:Rectangle):Point
		{
			var center:Point = new Point(sceneBounds.width/2, sceneBounds.height/2);
			
			if(current.spatial.x < (sceneBounds.left + current.swarmer.tether) ||
				current.spatial.x > (sceneBounds.right - current.swarmer.tether) ||
				current.spatial.y < (sceneBounds.top + current.swarmer.tether) ||
				current.spatial.y > (sceneBounds.bottom - current.swarmer.tether))
			{
				return seek(current, center);
			}
			
			return new Point();
		}
		
		private function flee(current:SwarmNode, targ:Point):Point
		{
			var desVel:Point = new Point(current.spatial.x - targ.x, current.spatial.y - targ.y);
			desVel.normalize(1);
			desVel.x *= current.motion.maxVelocity.x;
			desVel.y *= current.motion.maxVelocity.y;			
			return desVel.subtract(current.motion.velocity);
		}
		
		private function seek(current:SwarmNode, targ:Point):Point
		{
			var desVel:Point = new Point(targ.x - current.spatial.x, targ.y - current.spatial.y);
			desVel.normalize(1);
			desVel.x *= current.motion.maxVelocity.x;
			desVel.y *= current.motion.maxVelocity.y;			
			return desVel.subtract(current.motion.velocity);
		}
		
		private function multiply(p1:Point, num:Number):Point
		{
			return new Point(p1.x * num, p1.y * num);
		}
		
		private function dot(p1:Point, p2:Point):Number
		{
			return (p1.x * p2.x + p1.y * p2.y);
		}
	}
}