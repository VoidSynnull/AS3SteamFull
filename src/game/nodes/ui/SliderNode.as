package game.nodes.ui
{
	import ash.core.Node;
	
	import engine.components.MotionBounds;
	import engine.components.Spatial;
	
	import game.components.motion.Draggable;
	import game.components.motion.Edge;
	import game.components.ui.Ratio;
	import game.components.ui.Slider;
	
	public class SliderNode extends Node
	{
		public var slider:Slider;
		public var ratio:Ratio;
		public var spatial:Spatial;
		public var draggable:Draggable;
		public var bounds:MotionBounds;
		public var edge:Edge;
		public var optional:Array = [Edge];
	}
}