package game.components.entity.collider 
{
	import flash.geom.Point;
	
	import ash.core.Component;

	public class HazardCollider extends Component
	{
		public function HazardCollider()
		{
			velocity = new Point();
		}
		
		public var isHit:Boolean;
		public var coolDown:Number = 0;		// 'invincible' interval, during which entity cannot be hurt again
		public var interval:Number = 0; 	// amount of remaining time entity has left in hurt state (used in circumstances when entity may not collide with platform)
		public var velocity:Point;			// velocity vector applied to entity during first contact with hazard
		public var rotation:Number;			// speed of rotation applied to entity during while in hurt state
	}

}