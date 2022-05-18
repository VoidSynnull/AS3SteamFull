package game.scenes.mocktropica.mountain.nodes
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.timeline.Timeline;
	import game.scenes.mocktropica.mountain.components.MancalaBugComponent;
	
	public class MancalaBugNode extends Node
	{
		public var bug:MancalaBugComponent;
		public var display:Display;
		public var spatial:Spatial;
		public var motion:Motion;
		public var timeline:Timeline;
	}
}