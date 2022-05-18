package game.scenes.testIsland.physicsTest
{
	import flash.geom.Point;
	
	import ash.core.Component;
	
	import engine.components.Motion;
	
	import game.util.PointUtils;
	
	public class RigidBody extends Component
	{
		public var useGravity:Boolean;
		
		public var mass:Number;
		
		public var motion:Motion;
		
		public var timeStep:Number = 1;
		
		public function RigidBody(motion:Motion, mass:Number = 1, useGravity:Boolean = true)
		{
			this.motion = motion;
			this.mass = mass;
			this.useGravity = useGravity;
		}
		
		/* notes
		
		Force is a vector which has both direction and magnitude
		
		However I broke it up into both direction and magnitude
		
		to make it easier to use for those who may not completely understand vector math
		
		if you precalculate the magnitude into the direction be sure to leave foce as 1
		
		*/
		
		public function addForce(direction:Point, force:Number = 1, time:Number = 1):void
		{
			/*// where this comes from
			f = ma
			
			1/a = m/f
			
			a = f / m
			
			a = v / t
			
			v = a * t
			
			v = f / m * t
			
			*/
			
			direction.x = direction.x / mass * force * time;
			direction.y = direction.y / mass * force * time;
			motion.velocity = motion.velocity.add(direction);
		}
		
		/*notes
		
		if you want to simply rotate an object with out worrying from where
		
		I recomend passing in a new Point(0, 1) or new Point(0, -1) depending on the direction
		
		if you precalculate the magnitude into the direction be sure to leave foce as 1
		
		*/
		
		public function addTorque(direction:Point, force:Number = 1, time:Number = 1, position:Point = null):void
		{
			/* where this comes from
			
			T = r F sin(theta);
			
			T = torque
			
			r = the length of the lever used to apply force
			
			F = the force applied
			
			sin(theta) represents the angle of which the force is applied to the lever(effects direction and effectiveness)
			
			perfectly perpendicular is the most effective while being in line with the lever is completely ineffective
			
			*/
			
			var magnitude:Number = Math.sqrt(direction.x * direction.x + direction.y * direction.y);
			
			var armLength:Number = 1;
			
			var angle:Number = Math.atan2(direction.y, direction.x);
			
			if(position != null)
			{
				var origin:Point =  new Point(motion.x, motion.y);
				var positionAngle:Number = PointUtils.getRadiansBetweenPoints(origin, position);
				armLength = Point.distance(position, origin);
				angle -= positionAngle;
			}
			
			motion.rotationVelocity += armLength * magnitude * force * Math.sin(angle) / mass * time;
		}
		
		public function addForceAtPoint(direction:Point, point:Point, force:Number = 1, time:Number = 1):void
		{
			addForce(direction, force, time);
			addTorque(direction, force, time, point);
		}
	}
}