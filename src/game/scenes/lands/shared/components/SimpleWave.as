package game.scenes.lands.shared.components {

	import flash.geom.Point;
	
	import ash.core.Component;

	public class SimpleWave extends Component {

		/**
		 * contains the current wave angle, but can also be used to set the starting angle.
		 */
		public var curAngle:Number = 0;

		/**
		 * rate of wave motion in radians per second.
		 */
		public var omega:Number;

		/**
		 * the wave is applied to both x and y coordinates, but if the xAmplitude, yAmplitude is zero,
		 * there is no wave in that direction.
		 */
		public var xAmplitude:Number;
		public var yAmplitude:Number;

		/**
		 * origin of the wave - amplitude is taken from this location.
		 * if no origin is set, the entity's current location when added to the wave system
		 * is taken as the origin.
		 */
		public var origin:Point;

		public function SimpleWave( omega:Number=0, xAmp:Number=0, yAmp:Number=0 ) {

			super();

			this.omega = omega;
			this.xAmplitude = xAmp;
			this.yAmplitude = yAmp;


		} //

	} // class

} // package