package game.scenes.mocktropica.mountain.components
{
	import flash.geom.Point;
	
	import ash.core.Component;
	
	public class MancalaBeadComponent extends Component
	{
		public var state:String =			IDLE;
		public var timer:Number = 			0;
		public var magnitude:Number =		0;
		public var start:Point = 			new Point( 0, 0 );
		
		public const IDLE:String =			"idle";
		public const SHAKE:String =			"shake";
	}
}