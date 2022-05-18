package game.scenes.cavern1.shared.nodes
{
	import ash.core.Node;
	
	import engine.components.Motion;
	
	import game.components.entity.Children;
	import game.components.entity.collider.PlatformCollider;
	import game.scenes.cavern1.shared.components.Breakable;
	
	public class BreakableNode extends Node
	{
		public var breakable:Breakable;
		public var children:Children;
		public var motion:Motion;
		public var hit:PlatformCollider;
	}
}