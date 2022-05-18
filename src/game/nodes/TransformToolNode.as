package game.nodes
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Interaction;
	import engine.components.Spatial;
	
	import game.components.motion.TargetSpatial;
	import game.components.TransformTool;
	
	public class TransformToolNode extends Node
	{
		public var interaction:Interaction;
		public var tool:TransformTool;
		public var target:TargetSpatial;
		public var display:Display;
		public var spatial:Spatial;
	}
}