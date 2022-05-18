package game.components.motion
{
	import ash.core.Component;
	import flash.geom.Point;

	public class RadiusControl extends Component
	{
		public function RadiusControl( radius:int = 0, centerX:int = 0, centerY:int = 0 )
		{
			this.radius = radius;
			center = new Point();
			center.x = centerX;
			center.y = centerY;
		}
		
		public var radius:int;
		public var center:Point;
		public var rotationRange:Point;
		public var cameraOffset:Boolean;
		public var ease:Number;
		
		/**
		 * Sets the rotation range, adjusts so north = 0.
		 * @param	minRotation
		 * @param	maxRotation
		 */
		public function setRange( minRotation:int, maxRotation:int ):void
		{
			if ( !rotationRange )
			{
				rotationRange = new Point();
			}
			rotationRange.x = minRotation;
			rotationRange.y = maxRotation;
		}

	}
}