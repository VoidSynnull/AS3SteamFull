package game.scenes.myth.mountOlympus3.nodes
{
	import ash.core.Node;
	
	import engine.components.Audio;
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.OwningGroup;
	import engine.components.Spatial;
	import engine.components.Tween;
	
	import game.components.animation.FSMControl;
	import game.components.entity.EntityPoolComponent;
	import game.components.entity.character.animation.AnimationControl;
	import game.components.entity.character.animation.RigAnimation;
	import game.components.motion.Edge;
	import game.components.motion.MotionControl;
	import game.components.motion.MotionControlBase;
	import game.components.motion.MotionTarget;
	import game.components.motion.TargetSpatial;
	import game.components.timeline.Timeline;
	import game.scenes.myth.mountOlympus3.components.ZeusBoss;
	import game.scenes.myth.shared.components.ElectrifyComponent;
	
	public class ZeusStateNode extends Node
	{
		public var animControl:AnimationControl;
		public var audio:Audio;
		public var display:Display;
		public var edge:Edge;
		public var electric:ElectrifyComponent;
		public var fsmControl:FSMControl;
		public var motion:Motion;
		public var motionControl:MotionControl;
		public var motionTarget:MotionTarget;
		public var motionControlBase:MotionControlBase;
		public var owningGroup:OwningGroup;
		public var primary:RigAnimation;
		public var spatial:Spatial;
		public var targetSpatial:TargetSpatial;
		public var timeline:Timeline;
		public var tween:Tween;
		public var boss:ZeusBoss;
		public var entityPool:EntityPoolComponent;
	}
}