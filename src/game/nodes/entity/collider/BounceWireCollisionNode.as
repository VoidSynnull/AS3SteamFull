package game.nodes.entity.collider
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.motion.Edge;
	import game.components.entity.collider.BounceWireCollider;
	import game.components.hit.CurrentHit;
	import game.components.entity.collider.PlatformCollider;
	
	public class BounceWireCollisionNode extends Node
	{
		public var edge:Edge;
		public var motion:Motion;
		public var collider:BounceWireCollider;
		public var display:Display;
		public var spatial:Spatial;
		public var platformCollider:PlatformCollider;
		public var currentHit:CurrentHit;
	}
}