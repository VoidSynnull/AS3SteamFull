package game.nodes.render
{
	import ash.core.Node;
	
	import engine.components.Spatial;
	
	import game.components.render.Light;
	
	public class LightNode extends Node
	{
		public var light:Light;
		public var spatial:Spatial;
	}
}