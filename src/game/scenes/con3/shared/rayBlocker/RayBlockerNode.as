package game.scenes.con3.shared.rayBlocker
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Id;
	
	import game.components.hit.EntityIdList;
	
	public class RayBlockerNode extends Node
	{
		public var blocker:RayBlocker;
		public var entityIdList:EntityIdList;
		public var id:Id;
		public var display:Display;
	}
}