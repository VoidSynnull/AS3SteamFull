package game.nodes.motion
{
	import ash.core.Node;
	
	import engine.components.Motion;
	
	import game.components.motion.nape.NapeMotion;
	import game.components.motion.nape.PositionSyncToNape;
	
	public class PositionSyncToNapeNode extends Node
	{
		public var positionSyncToNape:PositionSyncToNape;
		public var motion:Motion;
		public var napeMotion:NapeMotion;
	}
}