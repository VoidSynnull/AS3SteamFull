package game.scenes.mocktropica.mountain.components
{
	import flash.geom.Point;
	
	import ash.core.Component;
	
	public class MancalaBugComponent extends Component
	{
		public var state:String = 		IDLE;
		
		public var crawlSpeed:Number = 	50;
		public var flySpeed:Number =	240;
		public var start:Point = 		new Point();
		public var target:Point = 		new Point();
		
		public const IDLE:String =		"idle";
		public const HIDE:String =		"hide";
		public const HIDDEN:String =	"hidden";
		public const SEEK:String =		"seek";
		public const MOVE:String =		"move";
		public const PANIC:String =		"panic";
		public const FLY:String =		"fly";
	}
}