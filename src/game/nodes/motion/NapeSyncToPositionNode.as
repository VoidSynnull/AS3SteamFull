package game.nodes.motion
{
	import ash.core.Node;
	
	import engine.components.Motion;
	
	import game.components.motion.nape.NapeMotion;
	import game.components.motion.nape.NapeSyncToPosition;
	
	public class NapeSyncToPositionNode extends Node
	{
		public var napeSyncToPosition:NapeSyncToPosition;
		public var motion:Motion;
		public var napeMotion:NapeMotion;
	}
}