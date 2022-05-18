package game.nodes.render
{
	import ash.core.Node;
	
	import game.components.hit.Platform;
	import game.components.render.PlatformDepthCollision;
	
	public class PlatformDepthCollisionNode extends Node
	{
		public var platformDepthCollision:PlatformDepthCollision;
		public var platform:Platform;
	}
}