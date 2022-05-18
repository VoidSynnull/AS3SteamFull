package game.scenes.myth.grove.nodes
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.scenes.myth.grove.components.LavaComponent;
	
	
	public class LavaNode extends Node
	{
		public var lava:LavaComponent;
		public var spatial:Spatial;
		public var display:Display;
	}
}