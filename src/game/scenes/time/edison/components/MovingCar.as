package game.scenes.time.edison.components
{
	import ash.core.Entity;
	
	import ash.core.Component;

	public class MovingCar extends Component
	{
		public var state:String;
		public var bigWheel:Entity;
		public var smallWheel:Entity;
		public var topPlatform:Entity;
		public var seatPlatform:Entity;
		public var stopX:Number;
		public var accel:Number;
	}
}