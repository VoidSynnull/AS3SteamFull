package game.scenes.ghd.shared.mushroomBouncer
{
	import ash.core.Node;
	
	import game.components.hit.CurrentHit;
	import game.components.motion.MotionControl;
	
	public class MushroomBouncerNode extends Node
	{
		public var mushroom:MushroomBouncer;
		public var currentHit:CurrentHit;
		public var motionControl:MotionControl;
	}
}