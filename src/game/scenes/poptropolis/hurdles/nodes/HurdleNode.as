package game.scenes.poptropolis.hurdles.nodes
{
	import ash.core.Node;
	
	import engine.components.Spatial;
	
	import game.components.timeline.Timeline;
	import game.scenes.poptropolis.hurdles.components.Hurdle;

	public class HurdleNode extends Node
	{
		public var hurdle:Hurdle;
		public var timeline:Timeline;
		public var spatial:Spatial;
	}
}