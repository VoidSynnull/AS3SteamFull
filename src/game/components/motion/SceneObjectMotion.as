package game.components.motion
{
	import ash.core.Component;
	
	public class SceneObjectMotion extends Component
	{
		public var edgeReboundFactor:Number = .8;		// determines amount of rebound, or bound, when colliding with MotionBounds
		public var platformFriction:Number = 200;		// friction of object, is applied to motion
		public var rotateByVelocity:Boolean = true;		// whether object should rotate while moving
		public var rotateByPlatform:Boolean = false;	// whether object should rotate in reference to platform slope
		public var applyGravity:Boolean = true;			// whether to apply constant downward acceleration (gravity)
	}
}