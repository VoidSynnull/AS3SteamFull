package game.nodes.motion
{
	import ash.core.Node;
	import game.components.motion.MotionTarget;
	
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.motion.MotionControl;
	import game.components.motion.MotionControlBase;
	import game.components.motion.Navigation;
	
	public class MotionByTargetNode extends Node
	{
		public var spatial:Spatial;
		public var motion:Motion;
		public var motionTarget:MotionTarget;
		public var motionControl:MotionControl;
		public var motionControlBase:MotionControlBase;
		public var navigation:Navigation;
	}
}