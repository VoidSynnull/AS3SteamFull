package game.nodes.render
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.components.render.LightOverlay;
	
	public class LightOverlayNode extends Node
	{
		public var lightOverlay:LightOverlay;
		public var display:Display;
		public var spatial:Spatial;
	}
}