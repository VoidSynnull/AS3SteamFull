package game.scenes.time.everest3.components
{
	import flash.geom.Point;
	import ash.core.Entity;
	import ash.core.Component;
	
	public class FallingIcicle extends Component
	{
		public var hit:Entity;
		public var state:String;
		public var velocity:Number;
		public var range:Point; // x = minY, y = maxY
		public var waitTime:Number;
		public var snowballs:Array;
	}
}