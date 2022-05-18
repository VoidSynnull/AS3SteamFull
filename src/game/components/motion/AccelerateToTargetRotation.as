package game.components.motion
{
	import ash.core.Component;
	
	public class AccelerateToTargetRotation extends Component
	{
		public function AccelerateToTargetRotation(rotationAcceleration:Number = 200, deadZone:Number = 0)
		{
			this.rotationAcceleration = rotationAcceleration;
			this.deadZone = deadZone;
		}
		
		public var rotationAcceleration:Number;      // acceleration to apply to rotationVelocity when turning.
		public var deadZone:Number;                  // Minimum rotation delta before turning
		public var lock:Boolean = false;         
	}
}