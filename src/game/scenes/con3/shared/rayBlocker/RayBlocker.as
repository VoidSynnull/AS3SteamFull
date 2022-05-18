package game.scenes.con3.shared.rayBlocker
{
	import flash.display.Shape;
	
	import ash.core.Component;
	import ash.core.Entity;
	
	public class RayBlocker extends Component
	{
		internal var _shape:Shape = new Shape();
		
		public var particles:Entity;
		
		public function RayBlocker()
		{
			//this._shape.visible = false;
		}
		
		public function get shape():Shape { return this._shape; }
	}
}