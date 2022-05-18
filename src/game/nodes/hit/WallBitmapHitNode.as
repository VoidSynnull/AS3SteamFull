package game.nodes.hit
{
	import ash.core.Node;
	
	import game.components.hit.EntityIdList;
	import engine.components.Id;
	
	import game.components.hit.BitmapHit;
	import game.components.hit.Wall;
	
	public class WallBitmapHitNode extends Node
	{
		public var hit:Wall;
		public var bitmapHit:BitmapHit;
		public var hits : EntityIdList;
		public var id : Id;
		public var optional:Array = [EntityIdList,Id];
	}
}
