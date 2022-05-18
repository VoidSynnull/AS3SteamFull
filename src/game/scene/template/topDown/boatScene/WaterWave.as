package game.scene.template.topDown.boatScene
{
	import ash.core.Component;
	
	public class WaterWave extends Component
	{
		public function WaterWave(step:Number = 0)
		{
			this.step = step;
		}
		
		public var baseScale:Number = 1;
		public var step:Number;
		public var frame:Number = 0;
		public var appearing:Boolean = false;
		public var initialRotation:Number = 45;
		public var rotationVariance:Number = 5;
		public var totalFrames:int = 6;
	}
}