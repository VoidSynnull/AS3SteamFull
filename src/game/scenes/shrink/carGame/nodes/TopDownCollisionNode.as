package game.scenes.shrink.carGame.nodes
{
	import ash.core.Node;
	
	import engine.components.Audio;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Motion;
	import engine.components.MotionBounds;
	import engine.components.OwningGroup;
	import engine.components.Spatial;
	import engine.components.Tween;
	
	import game.components.animation.FSMControl;
	import game.components.audio.HitAudio;
	import game.components.motion.Edge;
	import game.components.motion.MotionControl;
	import game.components.motion.MotionControlBase;
	import game.components.motion.MotionTarget;
	import game.components.timeline.Timeline;
	import game.components.entity.LooperCollider;
	import game.components.entity.MotionMaster;
	
	public class TopDownCollisionNode extends Node
	{
		public var audio:Audio;
		public var display:Display;
		public var edge:Edge;
		public var fsmControl:FSMControl;
		public var group:OwningGroup;
		public var hitAudio:HitAudio;
		public var id:Id;
		public var collider:LooperCollider;
		public var motion:Motion;
		public var motionBounds:MotionBounds;
		public var motionControl:MotionControl;
		public var motionControlBase:MotionControlBase;
		public var motionTarget:MotionTarget;
		public var motionMaster:MotionMaster;
		public var spatial:Spatial;
		public var timeline:Timeline;
		public var tween:Tween;
	}
}