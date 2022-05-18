package game.nodes.motion
{
	import ash.core.Node;
	
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.motion.Draft;
	
	public class DraftNode extends Node
	{
		public var draft:Draft;
		public var sptial:Spatial;
		public var motion:Motion;
	}
}