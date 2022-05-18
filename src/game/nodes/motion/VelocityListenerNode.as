package game.nodes.motion
{
	import engine.components.Motion;
	import game.components.motion.VelocityListener;
	import ash.core.Node;

	public class VelocityListenerNode extends Node
	{
		public var velocityListener : VelocityListener;
		public var motion : Motion;
	}
}