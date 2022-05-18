/**
 * Allows entities to collide with platforms.  
 */ 

package game.components.entity.collider 
{
	import ash.core.Component;

	public class PlatformCollider extends Component
	{
		public var isHit:Boolean = false;	        
		public var ignoreNextHit:Boolean;            // Will cause an entity to 'ignore' the next platform hit and pass through it.
		public var baseGround:Boolean;				 // True when en entity is on the 'floor' boundary of a scene.
		public var adjustMotion:Boolean = true;
		public var collisionAngleDegrees:Number = 0;
	}
}