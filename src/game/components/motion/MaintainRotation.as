package game.components.motion
{
	import ash.core.Component;
	
	import engine.components.Spatial;
	
	public class MaintainRotation extends Component
	{
		public function MaintainRotation(maxAngle:Number = 90,minAngle:Number = -90,startingRotation:Number = 0,startingScaleX:Number = 0,startingScaleY:Number = 0,lockRotation:Boolean = true,limitRotation:Boolean = false,flipX:Boolean = false,flipY:Boolean = false,parentSpatial:Spatial = null)
		{
			this.lockRotation = lockRotation;
			this.limitRotation = limitRotation;
			this.flipX = flipX;
			this.flipY = flipY;
			this.maxAngle = maxAngle;
			this.minAngle = minAngle;
			this.startingRotation = startingRotation;
			this.parentSpatial = parentSpatial;
			this.startingScaleX = startingScaleX;
			this.startingScaleY = startingScaleY;
			
			super();
		}
		
		// flags
		public var lockRotation:Boolean;
		public var limitRotation:Boolean;
		public var flipX:Boolean;
		public var flipY:Boolean;
		// limit rotation
		public var maxAngle:Number;
		public var minAngle:Number;
		public var startingRotation:Number;

		public var parentSpatial:Spatial = null;
		public var startingScaleX:Number;
		public var startingScaleY:Number;
		public var flippedX:Boolean;
		
	}
}