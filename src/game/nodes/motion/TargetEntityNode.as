package game.nodes.motion
{
	import engine.components.Spatial;
	import game.components.motion.MotionTarget;
	import game.components.motion.TargetEntity;
	
	import ash.core.Node;
	
	public class TargetEntityNode extends Node
	{
		public var spatial:Spatial;                    	// spatial of entity doing the following
		public var targetEntity:TargetEntity;    		// wraps Entity being targeted, and targeting parameters
		public var motionTarget:MotionTarget;			// control of entity doing the following.
	}
}