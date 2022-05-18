package game.nodes.hit
{
	import engine.components.Display;
	import game.components.hit.Ceiling;
	import ash.core.Node;
	import engine.components.Spatial;
	
	public class CeilingHitNode extends Node
	{
		public var spatial : Spatial;
		public var display : Display;
		public var hit : Ceiling;
	}
}
