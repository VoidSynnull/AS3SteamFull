package game.scenes.testIsland.physicsTest.ColliderTypes
{
	import flash.geom.Point;
	
	import game.scenes.testIsland.physicsTest.LineSegment;
	import game.scenes.testIsland.physicsTest.Collider.Collider;
	import game.scenes.testIsland.physicsTest.Collider.ColliderType;
	import game.scenes.testIsland.physicsTest.Collider.Collision;
	import game.scenes.testIsland.physicsTest.PhysicsSystem.PhysicsSystem;
	import game.util.PointUtils;
	
	public class LineCollider extends ColliderType
	{
		public var lineSegments:Vector.<LineSegment>;
		
		public function LineCollider(points:Vector.<Point> = null)
		{
			lineSegments = createLineSegments(points);
		}
		
		public static function createLineSegments(points:Vector.<Point>):Vector.<LineSegment>
		{
			if(points == null)
				return null;
			if(points.length < 2)
				return null;
			
			var segments:Vector.<LineSegment> = new Vector.<LineSegment>();
			
			for(var i:int = 0; i < points.length - 1; i++)
			{
				var point1:Point = points[i];
				var point2:Point = points[i+1];
				
				if(point2 == null)
				{
					++i;
					continue;
				}
				if(point1 == null)
					continue;
				
				segments.push(new LineSegment(point1, point2));
			}
			
			return segments;
		}
				
		override public function moveOutOfCollision(collision:Collision):Point
		{
			var origin:Point = new Point(collider.spatial.x, collider.spatial.y);
			if(collider.rigidBody == null)
				return origin;
			
			var hypotenuse:Number = PointUtils.getMagnitude(new Point(collider.spatial.width, collider.spatial.height)) / 2 - Point.distance(origin, collision.hitPosition);
			var angle:Number = PointUtils.getRadiansBetweenPoints(origin, collision.hitPosition) - PointUtils.getRadiansOfTrajectory(collision.normal);
			var move:Point = PointUtils.times(collision.normal,  Math.cos(angle) * hypotenuse);
			
			origin = origin.subtract(move);
			collider.rigidBody.motion.x -= move.x;
			collider.rigidBody.motion.y -= move.y;
			
			return origin;
		}
				
		override public function checkIfHit(collider:Collider, physics:PhysicsSystem):void
		{
			if(lineSegments == null)
				return;
			
			var collisions:Vector.<Collision> = new Vector.<Collision>();
			
			for(var i:int = 0; i < lineSegments.length; i++)
			{
				var line1:LineSegment = lineSegments[i].offsetBySpatial(this.collider.spatial);
				var checkedCollisions:Vector.<Collision> = collider.colliderType.checkIfHitBy(line1, this.collider, physics);
				var averageCollision:Collision = getAverageCollision(checkedCollisions);
				if(averageCollision != null)
					collisions.push(averageCollision);
			}
			
			averageCollision = getAverageCollision(collisions);
			if(averageCollision != null)
			{
				if(averageCollision.otherCollider.rigidBody == null)
					this.collider.staticCollisions.push(averageCollision);
				else
					this.collider.elasticCollisions.push(averageCollision);
			}
		}
		
		override public function checkIfHitBy(lineSegment:LineSegment, collider:Collider, physics:PhysicsSystem):Vector.<Collision>
		{
			if(physics.showHits)
				physics.drawLine(lineSegment, 0);
			
			var collisions:Vector.<Collision> = new Vector.<Collision>();
			
			for(var i:int = 0; i < lineSegments.length; i++)
			{
				var line2:LineSegment = lineSegments[i].offsetBySpatial(this.collider.spatial);
				
				if(physics.showHits)
					physics.drawLine(line2, 1);
				
				var collision:Collision = LineSegment.checkForCrossSection(lineSegment, collider, line2, this.collider, physics);
				if(collision != null)
					collisions.push(collision);
			}
			
			return collisions;
		}
	}
}