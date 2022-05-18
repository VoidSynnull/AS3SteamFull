package game.scenes.con3.shared.rayReflect
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;
	
	import game.components.hit.EntityIdList;
	import game.scenes.con3.shared.Ray;
	import game.scenes.con3.shared.rayCollision.RayCollision;
	import game.scenes.con3.shared.rayRender.RayRender;
	
	public class RayToReflectCollisionNode extends Node
	{
		public var ray:Ray;
		public var render:RayRender;
		public var rayCollision:RayCollision;
		public var rayToReflectCollision:RayToReflectCollision;
		public var display:Display;
		public var spatial:Spatial;
		public var entityIdList:EntityIdList;
		public var id:Id;
	}
}