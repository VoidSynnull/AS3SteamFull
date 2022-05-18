package game.nodes.hit
{
	import ash.core.Node;
	
	import engine.components.Id;
	
	import game.components.hit.CurrentHit;
	
	public class CurrentHitNode extends Node
	{
		public var currentHit:CurrentHit;
		public var id:Id;
		public var optional:Array = [Id];
	}
}