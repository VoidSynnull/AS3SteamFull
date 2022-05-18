package game.scenes.con3.shared.rayReflect
{
	import flash.display.Shape;
	
	import ash.core.Component;
	
	public class ReflectToRayCollision extends Component
	{
		internal var _shape:Shape = new Shape();
		
		public function ReflectToRayCollision()
		{
			super();
		}
		
		public function get shape():Shape { return this._shape; }
	}
}