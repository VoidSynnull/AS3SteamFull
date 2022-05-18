package game.scenes.testIsland.physicsTest.Collider
{
	import flash.geom.Point;
	
	import game.scenes.testIsland.physicsTest.LineSegment;
	import game.scenes.testIsland.physicsTest.PhysicsSystem.PhysicsSystem;

	public class ColliderType
	{
		private var _collider:Collider;
		
		public function ColliderType()
		{
			
		}
		
		public function set collider(collider:Collider):void{_collider = collider;}
		
		public function get collider():Collider{return _collider;}
		
		public static function getAverageCollision(collisions:Vector.<Collision>, rigidBody:Boolean = false):Collision
		{
			var averageCollision:Collision = null;
			var start:Point = new Point();
			var end:Point = new Point();
			for each ( var collision:Collision in collisions)
			{
				if(collision != null)
				{
					if(averageCollision == null)
					{
						averageCollision = collision;
						start = collision.intersectedLine.start;
						end = collision.intersectedLine.end;
					}
					else
					{
						averageCollision.normal = averageCollision.normal.add(collision.normal);
						averageCollision.hitPosition = averageCollision.hitPosition.add(collision.hitPosition);
						start = start.add(collision.intersectedLine.start);
						end = end.add(collision.intersectedLine.start);
						if(rigidBody)
							averageCollision.momentum = averageCollision.momentum.add(collision.momentum);
					}
				}
			}
			if(averageCollision != null)
			{
				averageCollision.normal.x /= collisions.length;
				averageCollision.normal.y /= collisions.length;
				
				averageCollision.hitPosition.x /= collisions.length;
				averageCollision.hitPosition.y /= collisions.length;
				
				start.x /= collisions.length;
				start.y /= collisions.length;
				
				end.x /= collisions.length;
				end.y /= collisions.length;
				
				averageCollision.intersectedLine = new LineSegment(start, end);
				
				if(rigidBody)
				{
					averageCollision.momentum.x /= collisions.length;
					averageCollision.momentum.y /= collisions.length;
				}
			}
			return averageCollision;
		}
		
		public function moveOutOfCollision(collision:Collision):Point{return null}
		
		public function checkIfHit(collider:Collider, physics:PhysicsSystem):void{ }
		
		public function checkIfHitBy(lineSegment:LineSegment, collider:Collider, physics:PhysicsSystem):Vector.<Collision>{ return null;}
	}
}