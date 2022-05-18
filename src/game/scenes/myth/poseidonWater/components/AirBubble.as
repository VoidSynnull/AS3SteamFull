package game.scenes.myth.poseidonWater.components
{
	import ash.core.Entity;
	
	import ash.core.Component;
	
	import game.components.entity.Sleep;
	import game.components.hit.Zone;
	
	public class AirBubble extends Component
	{
		public var state:String = AWAKE;
		
		public var hit:Entity;
		public var hitZone:Zone;
		public var hitSleep:Sleep;
		
		public var AWAKE:String = 		"awake";
		public var FALL_ASLEEP:String =	"fall_asleep";
		public var SLEEP:String =		"sleep";
		
		public var counter:int = 0;
		public var timer:int = 200;
	}
}