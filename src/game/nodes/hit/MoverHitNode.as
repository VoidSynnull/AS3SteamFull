package game.nodes.hit
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;
	
	import game.components.hit.EntityIdList;
	import game.components.hit.Mover;
	
	public class MoverHitNode extends Node
	{
		public var spatial:Spatial;
		public var display:Display;
		public var hit:Mover;
		public var hits : EntityIdList;
		public var id : Id;
		public var optional:Array = [EntityIdList,Id];
	}
}
