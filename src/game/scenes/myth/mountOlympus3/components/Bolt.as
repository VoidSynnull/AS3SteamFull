package game.scenes.myth.mountOlympus3.components
{
	
	import ash.core.Component;
	
	public class Bolt extends Component
	{
		public static const SPAWN:String 	= "spawn";
		public static const FLYING:String	= "flying";
		public static const END:String		= "end";
		public static const OFF:String		= "off";
		
		public static const PLAYER_BOLT:String = "player_bolt";
		public static const BOSS_BOLT:String = "boss_bolt";
		
		public var state:String = FLYING;
		public var timer:Number = 0;
		public var rotation:Number = 0;	// in radians
		public var speed:Number = 400;
		public var zeusReflected:Boolean = false;
		public var isEnemy:Boolean = false;
		public var index:int;
		public var duration:Number = 5;	// max time duration in seconds
		public var radiusFromSource:int = 100;
		public var damage:int = 1;
	}
}