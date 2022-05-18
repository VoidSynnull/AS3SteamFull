package game.nodes.hit
{
	import ash.core.Node;
	
	import engine.components.Id;
	
	import game.components.hit.BitmapHit;
	import game.components.hit.EntityIdList;
	import game.components.hit.Mover;
	
	public class MoverBitmapHitNode extends Node
	{
		public var bitmapHit:BitmapHit;
		public var hit:Mover;
		public var hits : EntityIdList;
		public var id : Id;
		public var optional:Array = [EntityIdList,Id];
	}
}
