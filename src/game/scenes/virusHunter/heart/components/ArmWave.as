package game.scenes.virusHunter.heart.components {

	import ash.core.Component;

	public class ArmWave extends Component {

		//public var angularVelocity:Number;
		public var frequency:Number;

		public var amplitude:Number;

		public var springConst:Number = 2;			// pull back to the center of the wave. (spring constant basically)
		public var baseTheta:Number;				// midpoint of the wave.

		//public var segmentPull:Number = 0.1;
		//public var maxOmega:Number;
		//public var timer:Number;

		public function ArmWave( frequency:Number=0.8, amplitude:Number=0.04*Math.PI, baseTheta:Number=0) {

			this.frequency = frequency;
			this.amplitude = amplitude;

			//this.angularVelocity = 2*Math.PI*frequency;

			this.baseTheta = baseTheta;

			setPeriod( 1/frequency );

			/*this.baseTheta = baseTheta;
			this.pull = pull;
			this.segmentPull = segmentPull;

			this.maxOmega = maxOmega;*/

		} //

		public function setPeriod( period:Number ):void {

			if ( period == 0 ) {

				frequency = 0;
				return;

			} //

			springConst = ( 2*Math.PI ) / period;
			springConst *= springConst;

			frequency = 1 / period;

		} //

	} // End Orientation

} // End package