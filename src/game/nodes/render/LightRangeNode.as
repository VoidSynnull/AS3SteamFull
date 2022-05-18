package game.nodes.render
{
	import ash.core.Node;
	
	import engine.components.Spatial;
	
	import game.components.render.Light;
	import game.components.render.LightRange;
	
	public class LightRangeNode extends Node
	{
		public var light:Light;
		public var spatial:Spatial;
		public var lightRange:LightRange;
	}
}