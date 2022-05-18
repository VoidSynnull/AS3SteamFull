package game.scenes.poptropolis.archery.nodes 
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.scenes.poptropolis.archery.components.Wind;
	
	public class WindNode extends Node
	{
		public var wind:Wind;
		public var display:Display;
		public var spatial:Spatial;
	}
}