package game.components.entity.collider
{
	import ash.core.Entity;
	
	import ash.core.Component;
	
	public class BounceWireCollider extends Component
	{
		public function BounceWireCollider(spread:Number = 20)
		{
			this.spread = spread;
		}
		
		public var spread:Number;
		public var colliding:Boolean = false;
		public var collider:Entity;
	}
}