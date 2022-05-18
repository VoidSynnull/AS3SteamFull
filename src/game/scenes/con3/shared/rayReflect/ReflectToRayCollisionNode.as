package game.scenes.con3.shared.rayReflect
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Id;
	
	import game.components.hit.EntityIdList;
	
	public class ReflectToRayCollisionNode extends Node
	{
		public var reflectoToRay:ReflectToRayCollision;
		public var display:Display;
		public var entityIdList:EntityIdList;
		public var id:Id;
	}
}