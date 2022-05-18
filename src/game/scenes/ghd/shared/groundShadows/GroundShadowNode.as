package game.scenes.ghd.shared.groundShadows
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;
	
	import game.components.motion.FollowTarget;
	
	public class GroundShadowNode extends Node
	{
		public var shadow:GroundShadow;
		public var spatial:Spatial;
		public var display:Display;
		public var id:Id;
		public var follow:FollowTarget;
	}
}