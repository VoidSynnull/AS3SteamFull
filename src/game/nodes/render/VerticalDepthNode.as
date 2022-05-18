package game.nodes.render
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Spatial;
	import game.components.render.VerticalDepth;
	
	public class VerticalDepthNode extends Node
	{
		public var depth:VerticalDepth;
		public var spatial:Spatial;
		public var display:Display;
	}
}