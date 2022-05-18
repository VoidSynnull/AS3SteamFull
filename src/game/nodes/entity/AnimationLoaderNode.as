package game.nodes.entity
{
	import game.components.entity.character.animation.AnimationSlot;
	import game.components.entity.character.animation.RigAnimation;
	import game.components.entity.character.Rig;
	import game.components.entity.Parent;
	import game.components.timeline.Timeline;
	import ash.core.Node;

	public class AnimationLoaderNode extends Node
	{
		public var rigAnim:RigAnimation;
		public var timeline:Timeline;
		public var rig:Rig;
		public var parent:Parent;
		public var animSlot:AnimationSlot;
	}
}
