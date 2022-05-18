package game.nodes.entity
{

	import engine.components.Spatial;
	import game.components.entity.Parent;
	import game.components.entity.character.part.Joint;
	import game.components.entity.character.animation.AnimationSlot;
	import ash.core.Node;
	import game.components.timeline.Timeline;

	public class JointAnimationNode extends Node
	{
		public var spatial:Spatial;
		public var joint:Joint;
		public var timeline:Timeline;
		public var animSlot:AnimationSlot;
		public var parent:Parent;
	}
}
