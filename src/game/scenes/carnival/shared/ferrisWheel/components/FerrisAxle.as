package game.scenes.carnival.shared.ferrisWheel.components {

	
	import ash.core.Component;

	/**
	 * Marker class for the axle of a ferris wheel.
	 */
	public class FerrisAxle extends Component {

		public var x:Number;
		public var y:Number;

		/**
		 * Angle in radians of the ferris wheel.
		 */
		public var theta:Number;

		/**
		 * might not use this. need some way to have ferris arms and swings access
		 * the angular velocity to determine how much to swing.
		 */
		public var _angularVelocity:Number = 0;

		public function FerrisAxle( x:Number, y:Number, theta:Number=0 ) {

			super();

			this.x = x;
			this.y = y;

			this.theta = theta;

		} //

	} // End FerrisAxle
	
} // End package