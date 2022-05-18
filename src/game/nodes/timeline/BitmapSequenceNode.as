package game.nodes.timeline
{
	import ash.core.Node;

	import game.components.timeline.Timeline;
	import game.components.timeline.BitmapSequence;
	import game.components.timeline.BitmapTimeline;

	public class BitmapSequenceNode extends Node
	{
		public var timeline:Timeline;
		public var sequence:BitmapSequence;
		public var bitmapTimeline:BitmapTimeline;
	}
}