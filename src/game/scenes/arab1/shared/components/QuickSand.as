package game.scenes.arab1.shared.components
{
	import flash.geom.Point;
	
	import ash.core.Component;
	
	public class QuickSand extends Component
	{
		public var sinkSpeed:Number = 80;
		public var depth:Number = 100;
		public var sinking:Boolean = false;
		public var fallThru:Boolean = false;
		public var startingPoint:Point;
	}
}