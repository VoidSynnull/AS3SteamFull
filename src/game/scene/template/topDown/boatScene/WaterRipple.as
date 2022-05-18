package game.scene.template.topDown.boatScene
{
	import ash.core.Component;
	
	public class WaterRipple extends Component
	{
		public function WaterRipple()
		{
			
		}

		public var baseGrowthRate:Number = .01;
		public var growRateMultiplier:Number = .02;
		public var baseFadeRate:Number = .005;
		public var motionBasedFadeRate:Number = .01;
		public var asset:String;
		public var motionFactor:Number = 1;
	}
}