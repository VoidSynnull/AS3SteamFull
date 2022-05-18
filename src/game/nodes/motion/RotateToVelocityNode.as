package game.nodes.motion
{
	import ash.core.Node;
	
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.motion.RotateToVelocity;
	
	public class RotateToVelocityNode extends Node
	{
		public var motion:Motion;
		public var spatial:Spatial;
		public var rotate:RotateToVelocity;
	}
}