package game.scenes.lands.shared.classes {

	import flash.utils.getTimer;

	public class LandClock {

		/**
		 * real-time mins in one day.
		 */
		public const minsPerDay:int = 30;
		public const ticksPerDay:int = 1000*60*this.minsPerDay;

		public const dayStartPercent:Number = 0.15;

		//public const nightStartPercent:Number = 0.7;
		public const twilightPercent:Number = 0.6;

		/**
		 * startingTicks represents the time of day when the clock began to tick.
		 * 
		 * this is computed by setting the clock to the day-start-time ( in number of ticks ) minus the current flash time. ( getTimer() )
		 * getTimer() is subtracted because to compute a current world time, you compute: world ticks = startingTicks + getTimer()
		 *
		 */
		private var startingTicks:int;

		public function LandClock() {

			this.resetTime();

		}

		public function resetTime():void {

			this.startingTicks = this.dayStartPercent*this.ticksPerDay - getTimer();

		} //

		/**
		 * advance the time by an hour or so for testing.
		 */
		public function advanceTime():void {

			this.startingTicks += ( this.ticksPerDay/24 );

		} //

		public function setStartTime( dayPct:Number ):void {

			this.startingTicks = dayPct*this.ticksPerDay - getTimer();

		} //

		public function isTwilight():Boolean {

			var pct:Number = this.getDayPercent();
			//|| (pct > 0.86 && pct < 0.93)
			if ( (pct > this.twilightPercent && pct < 0.7) ) {
				return true;
			}
			return false;

		} //

		public function isNight():Boolean {

			var pct:Number = this.getDayPercent();
			if ( pct < 0 || pct > this.twilightPercent ) {
				return true;
			} //

			return false;

		} //

		public function getDayPercent():Number {

			return Number( ( (this.startingTicks + getTimer()) % this.ticksPerDay ) / this.ticksPerDay );

		} //

	} // class
	
} // package