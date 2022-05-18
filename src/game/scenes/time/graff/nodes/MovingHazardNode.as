package game.scenes.time.graff.nodes
{
	import ash.core.Node;
	
	import engine.components.Motion;
	
	import game.components.motion.Threshold;
	import game.scenes.time.graff.components.MovingHazard;
	
	public class MovingHazardNode extends Node
	{
		public var movingHazard:MovingHazard;
		public var motion:Motion;
		public var threshHold:Threshold;
	}
}