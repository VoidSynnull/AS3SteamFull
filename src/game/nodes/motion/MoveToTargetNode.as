package game.nodes.motion
{
	import ash.core.Node;
	
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.motion.MotionControl;
	import game.components.motion.MotionControlBase;
	import game.components.motion.MotionTarget;
	
	public class MoveToTargetNode extends Node
	{
		public var spatial:Spatial;
		public var motion:Motion;
		public var motionControl:MotionControl;
		public var motionTarget:MotionTarget;
		public var motionControlBase:MotionControlBase;
		
	}
}