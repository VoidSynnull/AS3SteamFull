package game.scenes.virusHunter.lungs.components
{
	import ash.core.Component;
	
	import game.util.GeomUtils;
	import game.util.Utils;

	public class AirFlow extends Component
	{
		public var elapsedTime:Number;
		public var waitTime:Number;
		public var x:Number;
		public var y:Number;
		
		public var minTime:Number;
		public var maxTime:Number;
		public var acceleration:Number;
		
		public function AirFlow(minTime:Number = 0.5, maxTime:Number = 1, acceleration:Number = 1000)
		{
			this.elapsedTime = 0;
			this.waitTime = Utils.randNumInRange(minTime, maxTime);
			this.minTime = minTime;
			this.maxTime = maxTime;
			this.acceleration = acceleration;
			
			var radians:Number = GeomUtils.degreeToRadian(Utils.randInRange(-180, 180));
			this.x = this.acceleration * Math.cos(radians);
			this.y = this.acceleration * Math.sin(radians);
		}
	}
}