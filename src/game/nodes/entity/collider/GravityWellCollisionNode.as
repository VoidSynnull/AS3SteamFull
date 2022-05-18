package game.nodes.entity.collider
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.entity.collider.GravityWellCollider;
	import game.components.hit.CurrentHit;
	import game.components.motion.Edge;
	
	public class GravityWellCollisionNode extends Node
	{
		public var edge:Edge;
		public var motion:Motion;
		public var display:Display;
		public var spatial:Spatial;
		public var gravityWellCollider:GravityWellCollider;
		public var currentHit:CurrentHit;
	}
}