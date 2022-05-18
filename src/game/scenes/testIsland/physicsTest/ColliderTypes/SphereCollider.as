package game.scenes.testIsland.physicsTest.ColliderTypes
{
	import flash.geom.Point;
	
	import engine.components.Spatial;
	
	import game.scenes.testIsland.physicsTest.LineSegment;
	import game.scenes.testIsland.physicsTest.Collider.Collider;
	import game.scenes.testIsland.physicsTest.Collider.ColliderType;
	import game.scenes.testIsland.physicsTest.Collider.Collision;
	import game.scenes.testIsland.physicsTest.PhysicsSystem.PhysicsSystem;
	import game.util.PointUtils;
	
	public class SphereCollider extends ColliderType
	{
		public var radius:Number;
		public function SphereCollider(radius:Number = 100)
		{
			this.radius = radius;
		}
		
		override public function checkIfHit(collider:Collider, physics:PhysicsSystem):void
		{
			if(physics.showHits)
				physics.drawCircle(new Point(this.collider.spatial.x, this.collider.spatial.y), radius * this.collider.spatial.scale, 0);
			
			var origin:Point = new Point(this.collider.spatial.x, this.collider.spatial.y);
			var averageCollision:Collision;
			var collisions:Vector.<Collision> = new Vector.<Collision>();
			if(collider.colliderType is LineCollider)
			{
				var lineCollider:LineCollider = collider.colliderType as LineCollider;
				for(var i:int = 0; i < lineCollider.lineSegments.length; i ++)
				{
					var target:LineSegment = lineCollider.lineSegments[i];
					
					var targets:Vector.<Point> = new Vector.<Point>();
					targets.push(target.start.add(target.angle), new Point(-target.normal.x, -target.normal.y), target.end.subtract(target.angle));
					
					var origins:Vector.<Point> = new Vector.<Point>();
					origins.push(origin, new Point(), origin);
					
					for(var j:int = 0; j < targets.length; j++)
					{
						averageCollision = sphereHitDetection(origins[j], targets[j],this.collider.spatial,collider.colliderType,physics);
						if(averageCollision != null)
							collisions.push(averageCollision);
					}
				}
				averageCollision = getAverageCollision(collisions);
			}
			
			if(collider.colliderType is SphereCollider)
				averageCollision = sphereHitDetection(origin, new Point(collider.spatial.x, collider.spatial.y),this.collider.spatial,collider.colliderType,physics);
			
			if(averageCollision != null)
			{
				if(averageCollision.otherCollider.rigidBody == null)
					this.collider.staticCollisions.push(averageCollision);
				else
					this.collider.elasticCollisions.push(averageCollision);
			}
		}
		
		override public function moveOutOfCollision(collision:Collision):Point
		{
			var origin:Point = new Point(collider.spatial.x, collider.spatial.y);
			if(collider.rigidBody == null)
				return origin;
			
			var hypotenuse:Number = radius - Point.distance(origin, collision.hitPosition);
			var angle:Number = PointUtils.getRadiansBetweenPoints(origin, collision.hitPosition) - PointUtils.getRadiansOfTrajectory(collision.normal);
			var move:Point = PointUtils.times(collision.normal,  Math.cos(angle) * hypotenuse);
			
			origin = origin.subtract(move);
			collider.rigidBody.motion.x -= move.x;
			collider.rigidBody.motion.y -= move.y;
			
			return origin;
		}
		
		public function sphereHitDetection(origin:Point, target:Point, spatail:Spatial, collider:ColliderType, physics:PhysicsSystem):Collision
		{
			var direction:Number = PointUtils.getRadiansBetweenPoints(origin, target);
				
			var end:Point = new Point(-Math.cos(direction) * radius, Math.sin(direction) * radius);
			
			var detectSegment:LineSegment = new LineSegment(new Point(), end);
			
			var checkedCollisions:Vector.<Collision> = collider.checkIfHitBy(detectSegment.offsetBySpatial(spatail, false), this.collider, physics);
			
			var averageCollision:Collision = getAverageCollision(checkedCollisions);
			
			return averageCollision;
		}
		
		override public function checkIfHitBy(lineSegment:LineSegment, collider:Collider, physics:PhysicsSystem):Vector.<Collision>
		{
			if(physics.showHits)
				physics.drawLine(lineSegment, 1);
			
			var collisions:Vector.<Collision> = new Vector.<Collision>();
			
			var origin:Point = new Point(this.collider.spatial.x, this.collider.spatial.y);
			
			var point:Point = new Point();
			
			var r:Number = radius * this.collider.spatial.scale;
			
			// have to use a different method when slope is undefined
			
			if(lineSegment.angle.x == 0)
			{
				point.x = lineSegment.start.x;
				
				var distanceX:Number = Math.abs(point.x - origin.x);
				
				if(distanceX > r)
					return collisions;
				
				/*
				
				// circles equation
				(x - p)^2 + (y - q)^2 = r^2 
				
				find y
				
				(y - q)^2 = r^2 - (x - p)^2
				
				y - q = math.sqrt(r^2 - (x - p)^2)
				
				y = math.sqrt(r^2 - (x - p)^2) + q
				
				*/
				
				point.y = Math.sqrt(Math.pow(r, 2) - Math.pow((point.x - origin.x), 2)) + origin.y; // +
				
				checkIfPointIsInSegment(lineSegment, point, origin, collisions);
				
				point.y = -Math.sqrt(Math.pow(r, 2) - Math.pow((point.x - origin.x), 2)) + origin.y; // -
				
				checkIfPointIsInSegment(lineSegment, point, origin, collisions);
				
				return collisions;
			}
			
			/*where equation comes from
			
			x and y are the coordinates of where the line may intersect the circle
			
			p and q are the origin of the circle
			
			equation for a circle
			(x - p)^2 + (y - q)^2 = r^2 
			
			equation for a line
			y = mx + b
			
			subsittue for y in circles equation
			(x - p)^2 + (mx + b - q)^2 = r^2
			
			expand and combine like terms
			(m^2 + 1)x^2 + 2(mb - mq - p)x + (q^2 - r^2 + p^2 + b^2 - 2bq)
			
			Ax^2         + Bx              + C 
			
			quadratic formula
			
			if((B^2 - 4AC) < 0) line does not intersect
			
			x = (-B +- sqrt(B^2 - 4AC))/2A
			
			y = m((-B +- sqrt(B^2 - 4AC))/2A) + b
			
			*/
			
			// rise over run
			var m:Number = lineSegment.angle.y / lineSegment.angle.x;
			
			// y = mx + b --> b = y - mx
			var b:Number = lineSegment.start.y - m * lineSegment.start.x;
			
			var A:Number = (m * m + 1);
			
			var B:Number = 2 * (m * b - m * origin.y - origin.x);
			
			var C:Number = (origin.y * origin.y - r * r + origin.x * origin.x + b * b - 2 * b * origin.y);
			
			if(B * B - 4 * A * C < 0)
				return collisions;
			
			point.x = (-B + Math.sqrt(B * B - 4 * A * C)) / (2 * A); // +
			point.y = m * point.x + b;
			
			checkIfPointIsInSegment(lineSegment, point, origin, collisions);
			
			point.x = (-B - Math.sqrt(B * B - 4 * A * C)) / (2 * A); // -
			point.y = m * point.x + b;
			
			checkIfPointIsInSegment(lineSegment, point, origin, collisions);
			
			return collisions;
		}
		
		private function checkIfPointIsInSegment(lineSegment:LineSegment, point:Point, origin:Point, collisions:Vector.<Collision>):void
		{
			if(Point.distance(point, lineSegment.start) < lineSegment.length && Point.distance(point, lineSegment.end) < lineSegment.length)
			{
				var radians:Number = Math.atan2(point.y - origin.y, point.x - origin.x);
				
				var normal:Point = new Point(Math.cos(radians), Math.sin(radians));
				
				collisions.push(new Collision(collider, this.collider, lineSegment, normal, point));
			}
		}
	}
}