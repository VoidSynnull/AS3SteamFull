package game.scenes.testIsland.physicsTest.Collider
{
	import flash.geom.Point;
	
	import game.scenes.testIsland.physicsTest.LineSegment;
	import game.util.PointUtils;

	public class Collision
	{
		public var hitPosition:Point;
		public var normal:Point;
		public var momentum:Point;
		public var intersectedLine:LineSegment;
		public var myCollider:Collider;
		public var otherCollider:Collider;
		public function Collision(myCollider:Collider, otherCollider:Collider, intersectedLine:LineSegment, normal:Point, hitPosition:Point)
		{
			this.myCollider = myCollider;
			this.otherCollider = otherCollider;
			this.intersectedLine = intersectedLine;
			this.normal = normal;
			this.hitPosition = hitPosition;
			if(otherCollider.rigidBody != null)
				momentum = PointUtils.times(otherCollider.rigidBody.motion.velocity, otherCollider.rigidBody.mass);
		}
	}
}