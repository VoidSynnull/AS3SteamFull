package game.nodes.entity
{
	import ash.core.Node;
	
	import engine.components.Spatial;
	
	import game.components.entity.FollowClipInTimeline;
	
	public class FollowClipInTimelineNode extends Node
	{
		public var followClip:FollowClipInTimeline;
		public var spatial:Spatial;
	}
}