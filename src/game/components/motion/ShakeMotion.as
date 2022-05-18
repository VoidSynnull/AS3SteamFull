package game.components.motion
{
	import ash.core.Component;
	
	import org.flintparticles.twoD.zones.Zone2D;

	public class ShakeMotion extends Component
	{
		public function ShakeMotion( zone2D:Zone2D = null )
		{
			this.shakeZone = zone2D;
		}
		
		public var shakeZone:Zone2D;
		
		public var active:Boolean = true;
		public var speed:Number = NaN;
		public var counter:Number = 0;
		
		// toggles shaking on and off on time delay
		public var onInterval:Number = NaN;
		public var offInterval:Number = NaN;
		public var intervalCount:Number = 0;
		public var shaking:Boolean = true;
	}
}