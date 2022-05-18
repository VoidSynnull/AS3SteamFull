package game.scenes.myth.mountOlympus3.components
{
	import ash.core.Component;
	import ash.core.Entity;
	
	import engine.components.Spatial;
	
	public class Orb extends Component
	{
		public static const SPAWN:String 	= "spawn";
		public static const FULL_ORBIT:String =	"full_orbit";
		public static const ORBIT:String	= "orbit";
		public static const HOME:String		= "home";
		public static const DRIFT:String	= "drift";
		public static const END:String		= "end";
		public static const OFF:String		= "off";
		
		public static const BOSS_ORB:String = "orb";
		
		public var state:String = OFF;
		public var radius:Number = 140;
		public var orbitStep:Number = 0;
		public var startOrbitStep:Number = 0;
		public var increment:Number = Math.PI/30;
		public var maxRotation:Number = 3 * Math.PI;
		public var chaseTime:Number = 2;
		public var orbitTarget:Spatial;
		public var owner:Entity;

		public var timer:Number = 0;
		public var duration:Number = 125;
	}
}