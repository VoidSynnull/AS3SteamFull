package game.nodes.motion
{
	import ash.core.Node;
	
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.motion.AccelerateToTargetRotation;
	import game.components.motion.MotionTarget;
	
	public class AccelerateToTargetRotationNode extends Node
	{
		public var accelerateToTargetRotation:AccelerateToTargetRotation;
		public var motion:Motion;
		public var spatial:Spatial;
		public var motionTarget:MotionTarget;
	}
}