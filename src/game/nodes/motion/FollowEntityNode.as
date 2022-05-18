package game.nodes.motion
{
	import engine.components.Spatial;
	
	import game.components.motion.MotionControl;
	import game.components.motion.FollowEntity;
	
	import ash.core.Node;
	
	public class FollowEntityNode extends Node
	{
		public var spatial:Spatial;                    // spatial of entity doing the following
		public var followEntity:FollowEntity;    
		public var control:MotionControl;              // control of entity doing the following.
	}
}