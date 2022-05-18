package game.nodes.hit
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;
	
	import game.components.hit.EntityIdList;
	import game.components.hit.MovieClipHit;
	
	public class MovieClipHitNode extends Node
	{
		public var hit:MovieClipHit;
		public var spatial:Spatial;
		public var display:Display;
		public var id:Id;
		public var entityIdList:EntityIdList;
		public var optional:Array = [EntityIdList, Id];
	}
}