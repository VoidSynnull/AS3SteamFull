package game.nodes.motion
{
	import ash.core.Node;
	
	import engine.components.Audio;
	import engine.components.Display;
	import engine.components.Motion;
	
	import game.components.animation.procedural.PerspectiveAnimation;
	import game.components.motion.AccelerateToTargetRotation;
	import game.components.motion.MotionControl;
	import game.components.motion.MotionControlBase;
	import game.components.scene.Vehicle;
	
	public class VehicleMotionNode extends Node
	{
		public var vehicle:Vehicle;
		public var motion:Motion;
		public var motionControlBase:MotionControlBase;
		public var display:Display;
		public var audio:Audio;
		public var perspectiveAnimation:PerspectiveAnimation;
		public var accelerateToTargetRotation:AccelerateToTargetRotation;
		public var motionControl:MotionControl;
		public var optional:Array = [PerspectiveAnimation];
	}
}