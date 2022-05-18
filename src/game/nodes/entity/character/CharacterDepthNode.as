package game.nodes.entity.character
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.entity.DepthChecker;
	import game.components.entity.collider.PlatformCollider;

	public class CharacterDepthNode extends Node
	{
		public var spatial:Spatial;
		public var display:Display;
		public var motion:Motion;
		public var depthChecker:DepthChecker;
		public var collider:PlatformCollider;
	}
}