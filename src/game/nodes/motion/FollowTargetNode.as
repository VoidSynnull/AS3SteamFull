package game.nodes.motion
{
	import ash.core.Node;
	
	import engine.components.MotionBounds;
	import engine.components.Spatial;
	
	import game.components.motion.Draggable;
	import game.components.motion.Edge;
	import game.components.motion.FollowTarget;

	public class FollowTargetNode extends Node
	{
		public var follower : Spatial;
		public var followTarget : FollowTarget;
		
		public var draggable : Draggable;
		public var bounds:MotionBounds;
		public var edge:Edge;
		
		public var optional:Array = [ Draggable,MotionBounds,Edge ];
	}
}
