package game.nodes.motion
{
	import ash.core.Node;
	
	import engine.components.Motion;
	import engine.components.MotionBounds;
	import engine.components.Spatial;
	
	import game.components.motion.Edge;
	
	public class BoundsCheckNode extends Node
	{
		public var bounds:MotionBounds;
		public var spatial:Spatial;
		
		public var motion:Motion;
		public var edge:Edge;
		public var optional:Array = [Motion, Edge];
	}
}