package game.scenes.poptropolis.archery.nodes 
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.scenes.poptropolis.archery.components.Arrow;
	
	public class ArrowNode extends Node
	{
		public var arrow:Arrow;
		public var display:Display;
		public var spatial:Spatial;
	}
}