package game.components.entity.collider
{
	import flash.display.MovieClip;
	
	import ash.core.Component;
	
	public class RaceCollider extends Component
	{
		public var isHit:Boolean = false;						// when obstacle is hit
		public var type:String = "";							// type of obstacle
		public var hitClip:MovieClip;							// hit clip within obstacle
		public var halfWidth:Number;							// half-width from center
		public var halfHeight:Number							// half-height from center
		public var speed:int = 0;								// constant obstacle speed relative to roadway (positive number moves object upward)
		public var boostSpeed:uint = 0;							// additional speed when hit powerup (increases roadway speed)
		public var boostTime:Number = 0;						// time of powerup boost to last (in seconds)
		public var slickTime:Number = 0;						// time that player loses control when hitting oil slick (in seconds)
		public var hitSpeed:int = 0;							// speed of static object when hit (usually negative)
		public var hitTime:Number = 0;							// time for hitSpeed to decelerate to zero (in seconds)
		public var points:Number = 0;							// points assigned to collider
		public var looping:Boolean = false;						// looping animation
		public var inactive:Boolean = false;					// to make inactive
		public var hp:Number = 0;								// hp
		
		public static const MOVING:String = "moving";			// moving obstacle such as race car and gets knocked away
		public static const CRASHING:String = "crashing";		// moving obstacle such as race car and gets knocked away (but no points are lost)
		public static const STATIC:String = "static";			// static obstacle such as fire hydrant and gets knocked away
		public static const BOOST:String = "boost";				// static powerup which disappears when collided
		public static const PLACEMENT:String = "placement";		// static item that is NOT a collider but needs to be placed in scene such as the finish line
		public static const SLICK:String = "slick";				// static obstacle which does not disappear and causes player to lose control
		public static const OBSTACLE:String = "obstacle";			// static obstacle such as fire hydrant and gets knocked away
	}
}