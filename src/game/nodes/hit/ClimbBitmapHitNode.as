package game.nodes.hit
{
	import ash.core.Node;
	
	import engine.components.Id;
	
	import game.components.hit.BitmapHit;
	import game.components.hit.Climb;
	
	public class ClimbBitmapHitNode extends Node
	{
		public var hit:Climb;
		public var bitmapHit:BitmapHit;
		public var id:Id;
		public var optional:Array = [Id];
	}
}
