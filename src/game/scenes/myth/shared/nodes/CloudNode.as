package game.scenes.myth.shared.nodes
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.motion.FollowTarget;
	import game.scenes.myth.shared.components.Cloud;
	
	public class CloudNode extends Node
	{
		public var cloud:Cloud;
		public var display:Display;
		public var followTarget:FollowTarget;
		public var motion:Motion;
		public var spatial:Spatial;
	}
}