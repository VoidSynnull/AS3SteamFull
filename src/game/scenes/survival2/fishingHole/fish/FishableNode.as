package game.scenes.survival2.fishingHole.fish
{
	import ash.core.Node;
	
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.timeline.Timeline;
	import game.scenes.survival2.shared.components.Hookable;
	
	public class FishableNode extends Node
	{
		public var fish:Fishable;
		public var hookable:Hookable;
		public var spatial:Spatial;
		public var motion:Motion;
		public var timeline:Timeline;
	}
}