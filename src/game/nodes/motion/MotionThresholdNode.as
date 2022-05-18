package game.nodes.motion
{
	import ash.core.Node;
	import engine.components.Motion;
	import game.components.motion.MotionThreshold;
	
	public class MotionThresholdNode extends Node
	{
		public var motion : Motion;
		public var motionThreshold : MotionThreshold;
	}
}