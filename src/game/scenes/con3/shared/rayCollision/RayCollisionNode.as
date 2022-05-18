package game.scenes.con3.shared.rayCollision
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Id;
	
	import game.components.hit.EntityIdList;
	import game.scenes.con3.shared.Ray;
	import game.scenes.con3.shared.rayRender.RayRender;
	
	public class RayCollisionNode extends Node
	{
		public var ray:Ray;
		public var render:RayRender;
		public var rayCollision:RayCollision;
		public var display:Display;
		public var entityIdList:EntityIdList;
		public var id:Id;
	}
}