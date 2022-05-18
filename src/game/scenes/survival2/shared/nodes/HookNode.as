package game.scenes.survival2.shared.nodes
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.entity.Parent;
	import game.components.hit.CurrentHit;
	import game.components.entity.collider.PlatformCollider;
	import game.scenes.survival2.shared.components.Hook;
	
	public class HookNode extends Node
	{
		public var hook:Hook;
		public var display:Display;
		public var motion:Motion;
		public var spatial:Spatial;
		public var parent:Parent;
		public var currentHit:CurrentHit;
		public var platformCollider:PlatformCollider;
	}
}