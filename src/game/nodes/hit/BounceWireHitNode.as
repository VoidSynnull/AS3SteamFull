package game.nodes.hit
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.components.hit.BounceWire;
	
	public class BounceWireHitNode extends Node
	{
		public var spatial:Spatial;
		public var display:Display;
		public var hit:BounceWire;
	}
}