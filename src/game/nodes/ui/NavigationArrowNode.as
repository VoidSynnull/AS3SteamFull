package game.nodes.ui
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.components.input.Input;
	import game.components.motion.TargetSpatial;
	import game.components.timeline.Timeline;
	import game.components.ui.Cursor;
	import game.components.ui.NavigationArrow;
	
	public class NavigationArrowNode extends Node
	{
		public var navigationArrow:NavigationArrow;
		public var cursor:Cursor;
		public var spatial:Spatial;
		public var input:Input;
		public var display:Display;
		public var timeline:Timeline;
		public var targetSpatial:TargetSpatial;
	}
}