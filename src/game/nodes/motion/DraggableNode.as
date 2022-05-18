package game.nodes.motion
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Interaction;
	import engine.components.Spatial;
	
	import game.components.motion.Draggable;
	
	public class DraggableNode extends Node
	{
		public var draggable:Draggable;
		public var interaction:Interaction;
		public var display:Display;
		public var spatial:Spatial;
	}
}