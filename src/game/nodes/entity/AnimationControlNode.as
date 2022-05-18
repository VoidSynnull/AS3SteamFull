package game.nodes.entity
{
	
	import ash.core.Node;
	
	import game.components.animation.FSMControl;
	import game.components.entity.Parent;
	import game.components.timeline.Timeline;
	import game.components.entity.character.animation.AnimationControl;
	import game.components.entity.character.animation.AnimationSlot;
	import game.components.entity.character.animation.RigAnimation;

	public class AnimationControlNode extends Node
	{
		public var rigAnim:RigAnimation;			// this is here to prevent anim slot entities from using the animation control system, only used by parent entity taht 'owns' slots 
		public var animControl:AnimationControl;
		public var animSlot:AnimationSlot;
		public var timeline:Timeline;
		public var parent:Parent;
		
		public var fsmControl:FSMControl;
		public var optional:Array = [FSMControl];
	}
}
