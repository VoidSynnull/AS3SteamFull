package game.scenes.deepDive2.predatorArea.nodes
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.animation.FSMControl;
	import game.components.timeline.Timeline;
	import game.scenes.deepDive2.predatorArea.components.Shark;
	
	public class SharkNode extends Node
	{
		public var shark:Shark;
		public var timeline:Timeline;
		public var motion:Motion;
		public var display:Display;
		public var spatial:Spatial;
		public var fsmControl:FSMControl;
	}
}