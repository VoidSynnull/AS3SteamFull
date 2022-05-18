package game.scenes.arab1.shared.nodes
{
	import ash.core.Node;
	
	import engine.components.Id;
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.timeline.Timeline;
	import game.scenes.arab1.shared.components.SandScorpion;

	public class SandScorpionNode extends Node
	{
		public var scorpion:SandScorpion;
		
		public var spatial:Spatial;
		public var motion:Motion;
		public var id:Id;
		public var timeline:Timeline;
	}
}