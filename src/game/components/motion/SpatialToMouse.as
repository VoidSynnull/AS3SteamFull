package game.components.motion
{
	import flash.display.DisplayObject;
	
	import ash.core.Component;
	
	public class SpatialToMouse extends Component
	{
		public var container:DisplayObject;
		public var axis:String;
		public var locked:Boolean;
		
		public function SpatialToMouse(container:DisplayObject, axis:String = null, locked:Boolean = false)
		{
			this.container 	= container;
			this.axis		= axis;
			this.locked 	= locked;
		}
	}
}