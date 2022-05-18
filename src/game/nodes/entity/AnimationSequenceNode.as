package game.nodes.entity
{
	import ash.core.Node;
	
	import game.components.animation.FSMControl;
	import game.components.entity.character.CharacterMovement;
	import game.components.entity.character.animation.AnimationControl;
	import game.components.entity.character.animation.AnimationSequencer;
	import game.components.entity.character.animation.AnimationSlot;
	import game.components.entity.character.animation.RigAnimation;
	import game.components.timeline.Timeline;

	public class AnimationSequenceNode extends Node
	{
		public var animControl:AnimationControl;	// reference to character entity's AnimationSequencer
		public var animSequencer:AnimationSequencer;	
		public var rigAnim:RigAnimation;			// primary RigAnimation
		public var timeline:Timeline;				// Timeline of primary RigAnimation
		public var animSlot:AnimationSlot;		// A flag node that differentiates as animation slot entity
		
		public var fsmControl:FSMControl;
		public var charMovement:CharacterMovement;
		public var optional:Array = [FSMControl, CharacterMovement];
	}
}
