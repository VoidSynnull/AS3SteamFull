package game.components.entity.collider
{
	import ash.core.Component;
	
	public class PlatformReboundCollider extends Component
	{
		public var isHit:Boolean = false;	        
		public var bounce:Number = 0;
		public var collisionAngleDegrees:Number = 0;
	}
}