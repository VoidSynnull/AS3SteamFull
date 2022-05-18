package game.nodes.motion
{
	import ash.core.Node;
	
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.motion.MotionTarget;
	
	public class MotionTargetNode extends Node
	{
		public var spatial:Spatial;
		public var motionTarget:MotionTarget;
		public var motion:Motion;
		public var optional:Array = [Motion];
	}
}