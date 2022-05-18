package game.scenes.time.graff.components
{
	import flash.geom.Point;
	
	import ash.core.Component;
	import ash.core.Entity;
	
	public class MovingHazard extends Component
	{
		public var visible:Entity;
		public var leftThreshHold:Number;
		public var rightThreshHold:Number;
		public var isDart:Boolean = false;
		public var startingLocation:Point;
	}
}