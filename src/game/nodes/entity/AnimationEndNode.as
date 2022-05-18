package game.nodes.entity
{
	import game.components.entity.character.animation.AnimationControl;
	import game.components.entity.character.animation.AnimationSequencer;
	import game.components.entity.character.animation.AnimationSlot;
	import game.components.entity.character.animation.RigAnimation;
	import game.components.timeline.Timeline;
	import ash.core.Node;

	public class AnimationEndNode extends Node
	{
		public var rigAnim:RigAnimation;
		public var timeline:Timeline;
		public var animControl:AnimationControl;
		public var animSequencer:AnimationSequencer;
		public var animState:AnimationSlot;
	}
}
