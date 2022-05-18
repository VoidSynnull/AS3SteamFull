package game.nodes.hit
{
	import ash.core.Node;
	import engine.components.Id;
	import engine.components.Spatial;
	import game.components.hit.Item;
	
	public class ItemHitNode extends Node
	{
		public var spatial : Spatial;
		public var hit : Item;
		public var id : Id;
	}
}
