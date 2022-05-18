package game.nodes.entity.collider
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.entity.collider.ZoneCollider;
	
	public class ZoneCollisionNode extends Node
	{
		public var spatial : Spatial;
		public var motion : Motion;
		public var collider : ZoneCollider;
		public var display : Display;
		public var id : Id;
	}
}