package game.components.entity.collider
{
	import ash.core.Component;
	
	/**
	 * Detects radial hits, radial hits are used for curved collisions in which the collider can approach them from any direction.	 
	 */
	public class RadialCollider extends Component
	{
		public var angle:Number = 0;
		public var isHit:Boolean = false;
		public var rebound:Number = 0;  // can add extra rebound if needed.
	}
}