package game.scenes.deepDive3.shared.nodes
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.components.Tween;
	
	import game.components.animation.FSMControl;
	import game.components.motion.MotionControl;
	import game.components.motion.MotionControlBase;
	import game.components.motion.MotionTarget;
	import game.scenes.deepDive3.shared.components.Drone;

	public class DroneNode extends Node
	{
		public var motion:Motion;
		public var motionControl:MotionControl;
		public var motionTarget:MotionTarget;
		public var motionControlBase:MotionControlBase;
		public var drone:Drone;
		public var display:Display;
		public var spatial:Spatial;
		public var tween:Tween;
		public var fsmControl:FSMControl;
	}
}