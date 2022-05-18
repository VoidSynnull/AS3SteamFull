package game.scenes.poptropolis.promoDive.nodes 
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.components.timeline.Timeline;
	import game.components.hit.MovieClipHit;
	import game.scenes.poptropolis.promoDive.components.Shark;
	
	public class SharkNode extends Node
	{
		public var shark:Shark;
		public var display:Display;
		public var spatial:Spatial;
		public var timeline:Timeline;
		public var hit:MovieClipHit;
	}
}