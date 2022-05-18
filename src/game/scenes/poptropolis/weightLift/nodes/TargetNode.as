package game.scenes.poptropolis.weightLift.nodes 
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.scenes.poptropolis.weightLift.components.Target;
	
	public class TargetNode extends Node
	{
		public var target:Target;
		public var display:Display;
		public var spatial:Spatial;
	}
}