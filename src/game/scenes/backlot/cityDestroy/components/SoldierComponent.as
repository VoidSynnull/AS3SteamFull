package game.scenes.backlot.cityDestroy.components
{
	import flash.geom.Point;
	
	import ash.core.Component;
	
	public class SoldierComponent extends Component
	{
		public var pointA:Point;
		public var pointB:Point;
		
		public var speedCheck:Boolean = false;
		public var movingLeft:Boolean = true;
		
		public var deathTime:Number = 1.25;
		
		public var timeDead:Number = 0;
		
		public var state:String = 			"idle";
		
		public const IDLE:String =			"idle";
		public const TURN:String = 			"turn";
		public const MARCHING:String = 		"marching";
		public const DEAD:String = 			"dead";
	}
}