package game.scenes.time.renaissance.nodes
{
	import ash.core.Node;
	
	import engine.components.Id;
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.motion.MotionTarget;
	import game.scenes.time.renaissance.components.HitPulley;
	
	public class HitPulleyNode extends Node
	{
		public var hitPulley:HitPulley;
		public var id:Id;
		public var target:MotionTarget;
		public var motion:Motion;
		public var spatial:Spatial;
	}
}