package game.components.motion
{
	import flash.geom.Point;
	
	import ash.core.Component;
	import engine.components.Spatial;

	public class RotateControl extends Component
	{
		public var originInLocal:Boolean = false;	// if origin is in scene corrdinates, if false is in local coordinates
		public var targetInLocal:Boolean = true;	// if target is in scene corrdinates, if false is in local coordinates
		
		//public var originSceneToScreen:Boolean;	// converts origin from scene to screen coordinates, generally used when targeting input
		//public var targetSceneToScreen:Boolean;	// adds camera offset to origin, generally used if input need to rotate towards object in scene
		//public var adjustForViewportScale:Boolean = true;	// accountd for viewport scaling, necessary if origin and target 
		
		public var rotationRange:Point;
		public var origin:Spatial;
		
		public var velocity:Number;
		public var ease:Number;
		public var manualTargetRotation:Number;
		
		public var lock:Boolean = false;
		public var fromTargetToOrigin:Boolean = true;		// determines how angle is calculated
		public var syncHorizontalFlipping:Boolean = false; // TODO :: This is temporary, want a standalone system that manages parent scale and rotation
		
		/**
		 * Sets the rotation range, adjusts so west = 0.
		 * @param	minRotation
		 * @param	maxRotation
		 */
		public function setRange( minRotation:int, maxRotation:int):void
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