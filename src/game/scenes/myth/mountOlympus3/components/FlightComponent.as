package game.scenes.myth.mountOlympus3.components
{
	import flash.geom.Point;
	
	import ash.core.Component;
	
	public class FlightComponent extends Component
	{
		public var active:Boolean = true;
		public var move:Boolean;
		public var dampen:Boolean;
		public var speedMin:int = 100;
		public var speedMax:int = 800;
		public var minDist:int = 60;
		public var midDist:int = 120;
		public var maxDist:int = 300;
		public var dampener:Number = .6;
		public var spring:Number = 20;
		
		public var _velocity:Point = new Point();
	}
}


