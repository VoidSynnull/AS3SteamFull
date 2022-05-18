package game.scenes.poptropolis.weightLift.nodes 
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.scenes.poptropolis.weightLift.components.Weight;
	
	public class WeightNode extends Node
	{
		public var weight:Weight;
		public var display:Display;
		public var spatial:Spatial;
	}
}