package game.scenes.carnival.shared.ferrisWheel.components {
	
	import flash.geom.Point;
	
	import ash.core.Component;

	/**
	 * Makes a player stick to a platform without using a motion component for the platform.
	 * This allows the platform to be moved dynamically without a well-defined motion.
	 * 
	 * This class works in conjunction with a platform component and sets the effective
	 * platform velocity to be a (newX-oldX)/time
	 */
	public class StickyPlatform extends Component {

		public var prevX:Number;
		public var prevY:Number;

		/**
		 * To save on calculations, _velocity will only be checked/set when something
		 * actually hits the platform.
		 */
		public var _velocity:Point;

		/**
		 * When you hit the platform, motion factors multiply the platform's
		 * velocity before setting the player's velocity to match.
		 * In effect either friction or a push.
		 */
		public var motionFactorX:Number = 1;
		public var motionFactorY:Number = 1;

		public function StickyPlatform() {

			super();

			_velocity = new Point();

		}

	} // End StickyPlatform

} // End package