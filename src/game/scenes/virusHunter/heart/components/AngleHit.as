package game.scenes.virusHunter.heart.components {

	import ash.core.Component;

	/**
	 * Angle hit is expected to be a rotated rectangle with its origin in the center.
	 */
	public class AngleHit extends Component {

		/**
		 * width,height of the unrotated rectangle.
		 */
		public var height:Number;
		public var thickness:Number;

		/**
		 * cos,sin of the rotation.
		 */
		public var cos:Number;
		public var sin:Number;

		// 1 is perfect rebound. Smaller numbers damp the rebound, larger numbers give artificial bounce.
		// 0 is no rebound.
		public var rebound:Number = 0.5;

		public var useSpatialAngle:Boolean=true;
		public var enabled:Boolean = true;

	} // End class

} // End package