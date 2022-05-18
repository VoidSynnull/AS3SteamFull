package game.nodes.motion
{
	import engine.components.Motion;
	import engine.components.Spatial;
	import game.components.motion.MotionControl;
	import game.components.motion.MotionTarget;
	import game.components.motion.Navigation;
	import ash.core.Node;

	public class NavigationNode extends Node
	{
		public var navigation:Navigation;
		public var spatial:Spatial;
		public var motionControl:MotionControl;
		public var motionTarget:MotionTarget;
		public var motion:Motion;
	}
}
