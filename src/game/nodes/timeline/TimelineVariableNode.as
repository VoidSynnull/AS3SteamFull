package game.nodes.timeline
{
	import ash.core.Node;
	
	import game.components.timeline.Timeline;
	import game.components.timeline.TimelineMasterVariable;

	public class TimelineVariableNode extends Node
	{
		public var timeline : Timeline;
		public var masterVariable : TimelineMasterVariable;		
	}
}
