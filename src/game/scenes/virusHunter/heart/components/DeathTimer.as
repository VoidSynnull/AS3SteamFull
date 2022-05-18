package game.scenes.virusHunter.heart.components {

	import ash.core.Component;

	public class DeathTimer extends Component {

		/**
		 * Remove the entity when the death timer completes.
		 */
		public var removeOnDeath:Boolean = true;

		/**
		 * Time it takes for the thing to completely die off.
		 */
		public var dieTime:Number;

		// Starts at the total death time and decreases towards 0.
		public var timer:Number;

		/**
		 * Blink stuff: blinkTimer increases as the inverse exponential of the total timer (which is heading to 0)
		 * So blinkTimer starts increasing by small amounts and at the limit, increases by 1 per frame.
		 * Whenever blinkTime goes above the blinkRate, the visibility toggles and the blinkTimer is reset.
		 * This produces a blink via Science(tm)
		 */
		public var blinkRate:Number = 0;
		public var blinkTimer:Number;

		public var lowAlpha:Number = 0.2;
		public var highAlpha:Number = 0.8;

		//
		public var blinkOn:Boolean = true;
		public var fadeOn:Boolean = false;

		public function DeathTimer( dieTime:Number=1, blinkRate:Number=0 ) {

			this.dieTime = dieTime;

			this.blinkRate = blinkRate;

		} //

		public function setBlink( blinkRate:Number ):void {

			blinkOn = true;
			this.blinkRate = blinkRate;

		} //

	} // End class

} // End package