package game.scenes.con3.shared.rayReflect
{
	import ash.core.Component;
	
	public class RayToReflectCollision extends Component
	{
		internal var _parent:RayToReflectCollisionNode;
		internal var _parentReflect:ReflectToRayCollisionNode;
		internal var _childReflect:ReflectToRayCollisionNode;
		
		public function RayToReflectCollision()
		{
			
		}
		
		public function get parent():RayToReflectCollisionNode
		{
			return this._parent;
		}
		
		public function get parentReflect():ReflectToRayCollisionNode
		{
			return this._parentReflect;
		}
	}
}