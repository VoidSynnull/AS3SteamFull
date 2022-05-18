package game.scenes.examples.bounceMaster.nodes
{
	import ash.core.Node;
	
	import engine.components.Motion;
	import engine.components.MotionBounds;
	import engine.components.Spatial;
	
	import game.components.motion.Edge;
	import game.components.hit.ProximityHit;
	import game.scenes.examples.bounceMaster.components.Bouncer;
	
	public class BouncerNode extends Node
	{
		public var bouncer:Bouncer;
		public var spatial:Spatial;
		public var hit:ProximityHit;
		public var motion:Motion;
		public var motionBounds:MotionBounds;
		public var edge:Edge;
	}
}