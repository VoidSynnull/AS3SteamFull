package game.nodes.entity
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.components.motion.Edge;
	import game.components.entity.Sleep;

	public class SleepNode extends Node
	{
		public var spatial:Spatial;
		public var sleep:Sleep;
		public var display:Display;
		public var edge:Edge;
		public var optional:Array = [Edge,Display];
	}
}
