package game.data.scene.hit
{
	public class HitType
	{
		public static const DOOR:String = "door";
		public static const CEILING:String = "ceiling";
		public static const WALL:String = "wall";
		public static const ITEM:String = "item";
		public static const BOUNCE:String = "bounce";					// a platform that adds upward velocity to entity		
		public static const CLIMB:String = "climb";
		public static const MOVER:String = "mover";
		public static const PLATFORM:String = "platform";
		public static const PLATFORM_TOP:String = "platformTop";  		// a platform where the entity is moved to the top the top rather than centering
		public static const INTERACTION:String = "interaction";
		public static const ANIMATION:String = "animation";
		public static const MOVING_PLATFORM:String = "movingPlatform";
		public static const MOVING_HIT:String = "movingHit";         	// an area which adds motion to an entities own motion.
		public static const HAZARD:String = "hazard";
		public static const SCENE:String = "scene";                   	// a hit with a motion component that can react to other hits.
		public static const WATER:String = "water";                  	// a hit with a motion component that can move other entities.
		public static const ZONE:String = "zone";                       // a hit that dispatches signals when entered, exitted and inside but doesn't effect entity directly.
		public static const RADIAL:String = "radial";                   // a hit which causes a collision reaction based on the angle of impact.
		public static const REFLECTIVE:String = "reflective";           // makes a hit area reflective.
		public static const WIRE_BOUNCE:String = "wireBounce";			// make a wire a bounce that bends the wire
		public static const LOOPER:String = "looper";					// a hit with a motion component that will loop when it passes off screen
		public static const PLATFORM_REBOUND:String = "platformRebound";
		public static const EMITTER:String = "emitter";					// control particle emitters by colision type
	}
}