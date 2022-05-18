package game.components.render
{
	import ash.core.Component;
	
	/**
	 * Author: Drew Martin
	 */
	public class Reflective extends Component
	{
		public static const SURFACE_BACK:int 	= 0;
		public static const SURFACE_DOWN:int 	= 1;
		public static const SURFACE_UP:int 		= 2;
		public static const SURFACE_LEFT:int 	= 3;
		public static const SURFACE_RIGHT:int 	= 4;
		
		/**
		 * Determines the behavior of a Reflective surface. This tells the system what "3D plane" to act as,
		 * and moves Reflections accordingly. For example, using <code>SURFACE_RIGHT</code> will make the surface
		 * act as a wall on the right. Reflections will then move closer as the Entity moves right, and farther
		 * as the Entity moves left.
		 */
		public var surface:int;
		
		/**
		 * Determines what type of Reflective Entity it is. If a Reflection's Dictionary of types has this type,
		 * it will be drawn to this Reflective surface.
		 */
		public var type:String;
		
		/**
		 * The value of <code>offsetX</code> offsets Reflections on the x axis. This is mainly used with
		 * <code>Reflective.SURFACE_BACK</code> to prevent Reflections from being drawn directly behind
		 * Entities where they can't be seen.
		 */
		public var offsetX:Number;
		
		/**
		 * The value of <code>offsetY</code> offsets Reflections on the y axis. This is mainly used with
		 * <code>Reflective.SURFACE_BACK</code> to prevent Reflections from being drawn directly behind
		 * Entities where they can't be seen.
		 */
		public var offsetY:Number;
		
		/**
		 * The amount of time to wait before the bitmap gets refreshed.
		 */
		public var waitTime:Number = 0.015;
		public var elapsedTime:Number = 0;
		
		public function Reflective(surface:int = Reflective.SURFACE_BACK, type:String = "default", offsetX:Number = 10, offsetY:Number = -10)
		{
			this.surface 	= surface;
			this.type 		= type;
			
			this.offsetX	= offsetX;
			this.offsetY	= offsetY;
		}
	}
}