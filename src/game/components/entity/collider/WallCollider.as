/**
 * A component to allow entities to collide with walls.
 */

package game.components.entity.collider
{
	import ash.core.Component;

	public class WallCollider extends Component
	{
		public var isHit:Boolean;
		public var isPushing:Boolean;	// flag determining if 'wall' object is being pushed (e.g. would be true if colliding with a box)
		public var direction:int;		// positive direction is right, negative direction is left
	}
}