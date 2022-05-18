package game.scenes.viking.shared.fishing
{
	import ash.core.Node;
	
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.entity.OriginPoint;
	import game.components.motion.Threshold;
	import game.components.timeline.Timeline;
	import game.scenes.viking.shared.fishing.Fish;
	
	public class FishNode extends Node
	{
		public var fish:Fish;
		public var timeline:Timeline;
		public var spatial:Spatial;
		public var motion:Motion;
		public var threshHold:Threshold;
		public var origin:OriginPoint;
	}
}