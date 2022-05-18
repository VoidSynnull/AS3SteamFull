package game.nodes.timeline
{
	import game.components.entity.character.animation.AnimationSlot;
	import game.components.entity.character.animation.RigAnimation;
	import game.components.entity.character.Rig;
	import game.components.entity.Parent;

	import game.components.timeline.Timeline;
	import game.components.timeline.TimelineMaster;
	import ash.core.Node;

	public class TimelineRigNode extends Node
	{
		public var parent:Parent;
		public var rig:Rig;
		public var timeline:Timeline;
		public var timelineMaster:TimelineMaster
		public var rigAnim:RigAnimation;
		public var animSlot:AnimationSlot;
	}
}
