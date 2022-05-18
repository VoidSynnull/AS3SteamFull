package game.scenes.backlot.sunriseStreet.components
{
	import flash.geom.Point;
	
	import ash.core.Component;
	import engine.components.Spatial;
	
	public class Earthquake extends Component
	{
		public var range:Point;
		public var shakeSpeed:Number;
		public var shakeTime:Number;
		public var origin:Spatial;
		public var offset:Point;
		public var severity:Number;
		
		public function Earthquake(origin:Spatial, range:Point, severity:Number = 1, speed:Number = 25, offset:Point = null)
		{
			shakeTime = 0;
			this.origin = origin;
			this.offset = offset;
			this.range = range;
			this.severity = severity;
			this.shakeSpeed = speed;
		}
	}
}