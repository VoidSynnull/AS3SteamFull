package game.scenes.myth.sphinx.nodes
{
	import ash.core.Node;
	
	import engine.components.Audio;
	import engine.components.Display;
	
	import game.components.timeline.Timeline;
	import game.scenes.myth.sphinx.components.WaterWayComponent;
	
	public class WaterWayNode extends Node
	{
		public var audio:Audio;
		public var display:Display;
		public var waterWay:WaterWayComponent;
		public var timeline:Timeline;
	}
}