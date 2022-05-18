package game.scenes.poptropolis.mainStreet.components
{
	import ash.core.Component;
	import engine.components.Spatial;
	
	public class ScreenShake extends Component
	{
		public var target:Spatial;
		
		public var radius:Number;
		public var rate:Number;
		public var time:Number = 0;
		
		public var y:Number = 0;
		
		//The camera shouldn't get any lower than this, or it won't shake because of camera bounds.
		public var limitY:Number = 1420;
		
		public var shakeWait:Number = 4; //Haha, Shake Weight...
		public var shakeTime:Number = shakeWait;
		
		public var shaking:Boolean = false;
		
		public var pauseWait:Number = 10;
		public var pauseTime:Number = 0;
		
		public function ScreenShake(target:Spatial, rate:Number = 25, radius:Number = 8)
		{
			this.target = target;
			this.rate 	= rate;
			this.radius = radius;
		}
	}
}