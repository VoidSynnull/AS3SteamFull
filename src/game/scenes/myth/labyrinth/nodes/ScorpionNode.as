package game.scenes.myth.labyrinth.nodes
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.hit.Hazard;
	import game.components.timeline.Timeline;
	import game.scenes.myth.labyrinth.components.ScorpionComponent;
	
	public class ScorpionNode extends Node
	{
		public var scorpion:ScorpionComponent;
		public var display:Display;
		public var motion:Motion;
		public var spatial:Spatial;
		public var hit:Hazard;
		public var timeline:Timeline;
	}
}