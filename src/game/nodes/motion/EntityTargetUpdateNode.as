package game.nodes.motion
{
	import engine.components.Spatial;
	import game.components.motion.MotionTarget;
	
	import game.components.motion.MotionControl;
	
	import ash.core.Node;
	
	public class EntityTargetUpdateNode extends Node
	{
		public var spatial:Spatial;                    	// spatial of entity doing the following
		public var motionControl:MotionControl;			// control of entity doing the following.
		public var motionTarget:MotionTarget;			// control of entity doing the following.
	}
}