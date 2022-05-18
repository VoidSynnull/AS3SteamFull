package game.nodes.hit
{
	import ash.core.Node;
	
	import engine.components.Display;
	import game.components.hit.EntityIdList;
	import engine.components.Id;
	import engine.components.Spatial;
	
	import game.components.hit.Wall;
	
	public class WallHitNode extends Node
	{
		public var spatial : Spatial;
		public var display : Display;
		public var hit : Wall;
		public var hits : EntityIdList;
		public var id : Id;
		public var optional:Array = [EntityIdList,Id];
	}
}
