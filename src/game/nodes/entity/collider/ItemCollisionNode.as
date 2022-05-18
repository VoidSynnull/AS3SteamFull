package game.nodes.entity.collider
{
	import engine.components.Spatial;
	import engine.components.Motion;
	import game.components.entity.collider.ItemCollider;
	
	import ash.core.Node;
	
	public class ItemCollisionNode extends Node
	{
		public var spatial : Spatial;
		public var motion : Motion;
		public var collider : ItemCollider;
	}
}
