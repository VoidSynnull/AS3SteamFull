package game.scenes.poptropolis.archery.nodes 
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.scenes.poptropolis.archery.components.Flag;
	
	public class FlagNode extends Node
	{
		public var flag:Flag;
		public var display:Display;
		public var spatial:Spatial;
	}
}