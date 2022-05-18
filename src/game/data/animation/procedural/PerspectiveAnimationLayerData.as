package game.data.animation.procedural
{
	import flash.display.DisplayObjectContainer;

	/**
	 * A value object for storing properties used by the PerspectiveAnimationSystem which applies the following formula:
	 * 
	 * displayObject[property] = offset + multipler * operation(PerspectiveAnimationComponent.frame);
	 * 
	 * It uses the 'frame' property of the perspectiveAnimation component to 'advance' the animation.
	 */
	
	public class PerspectiveAnimationLayerData
	{
		public function PerspectiveAnimationLayerData()
		{

		}
		
		public var displayObject:DisplayObjectContainer;
		public var property:String;     // a property to be adjusted (scaleX, scaleY, x, y or rotation most likely);
		public var offset:Number = 0;   // an offset to be added to the property
		public var multiplier:Number = 1;// A multiplier to be applied to the operation(step)
		public var operation:Function;  // A math operation to be applied to the frame (Math.sin, Math.cos, etc)
		public var operationAbs:Boolean = false;  // Should the operation be an absolute value?
		public var id:String;           // An optional id.
	}
}