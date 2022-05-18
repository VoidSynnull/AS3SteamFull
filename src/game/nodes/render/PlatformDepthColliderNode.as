package game.nodes.render
{
	import ash.core.Node;
	
	import engine.components.Display;
	
	import game.components.hit.CurrentHit;
	import game.components.render.PlatformDepthCollider;
	
	public class PlatformDepthColliderNode extends Node
	{
		public var platformDepthCollider:PlatformDepthCollider;
		public var display:Display;
		public var currentHit:CurrentHit;
		public var optional:Array = [CurrentHit];
	}
}