package game.scenes.backlot.cityDestroy.components
{
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import ash.core.Component;
	
	public class JetComponent extends Component
	{
		public var state:String = 		"turn";
		public var movingLeft:Boolean = false;
		public var speedCheck:Boolean = false;
		
		public var deltaY:Number = 0;
		public var deltaX:Number = -10;
		
		public var level:Number;
		public var shootTimer:Number = 0;
		public var shellUrl:String;
		
		public var hit:MovieClip;
		
		public var angle:Number;
		
		public var trajectoryX:Number;
		public var trajectoryY:Number;
		
		public var propellor:Entity;
		public var explosion:Entity;
		
		public var speed:Number = 150;
	}
}