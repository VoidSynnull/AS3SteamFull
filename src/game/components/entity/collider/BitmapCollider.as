/**
 * A component to allow entities to collide with bitmap hit areas (excluding platforms, which use BitmapPlatformCollider).
 */

package game.components.entity.collider
{
	import ash.core.Component;
	
	public class BitmapCollider extends Component
	{
		public var color:uint;
		public var hitX:Number;
		public var hitY:Number;
		public var lastX:Number;
		public var lastY:Number;

		public var platformColor:uint;
		public var platformHitX:Number;
		public var platformHitY:Number;
		
		public var centerColor:uint;
		public var centerHitX:Number;
		public var centerHitY:Number;
				
		public var ratioX:Number;
		public var ratioY:Number;
		
		public var lastRadialX:Number;
		public var lastRadialY:Number;
		
		public var addAccelerationToVelocityVector:Boolean = false;
		public var useEdge:Boolean = false;
	}
}