package game.scenes.survival5.chase.nodes
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.OwningGroup;
	import engine.components.Spatial;
	
	import game.components.animation.FSMControl;
	import game.components.entity.Children;
	import game.components.entity.Dialog;
	import game.components.entity.character.CharacterMotionControl;
	import game.components.entity.character.CharacterMovement;
	import game.components.entity.character.Player;
	import game.components.entity.character.Rig;
	import game.components.entity.character.animation.AnimationControl;
	import game.components.entity.character.animation.RigAnimation;
	import game.components.entity.collider.PlatformCollider;
	import game.components.motion.Edge;
	import game.components.motion.MotionControl;
	import game.components.motion.MotionTarget;
	import game.components.timeline.Timeline;
	import game.components.entity.LooperCollider;
	import game.components.entity.MotionMaster;
	
	public class RunningCharacterStateNode extends Node
	{
		public var fsmControl:FSMControl;
		
		public var children:Children; 	// keep a reference to the ui Head for velocity updates
		public var player:Player;
		public var rig:Rig;
		public var dialog:Dialog;
		public var animControl:AnimationControl;
		public var primary:RigAnimation;
		public var timeline:Timeline;
		public var spatial:Spatial;
		public var motion:Motion;
		public var edge:Edge;
		
		public var display:Display
		public var owningGroup:OwningGroup;
		
//		public var charMovement:CharacterMovement;
//		public var collider:LooperCollider;
		public var charMotionControl:CharacterMotionControl;
		public var motionControl:MotionControl;
		public var platformCollider:PlatformCollider;
		public var looperCollider:LooperCollider;
		public var motionTarget:MotionTarget;
		
		public var motionMaster:MotionMaster;
		public var optional:Array = [ MotionMaster ];
	}
}