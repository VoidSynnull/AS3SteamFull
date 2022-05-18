package game.scenes.lands.shared.components {

	/**
	 * This class and its associated systems are an extended version of the RobotBossBattle life system,
	 * but I didn't want to use that because I don't know if it will break anything. Maybe merge in the future.
	 * 
	 */

	import ash.core.Component;
	
	public class Life extends Component {

		/**
		 * life per second, approximately.
		 */
		public var regenRate:Number = 0;

		/**
		 * curLife tweens toward target life so life doesn't disappear all at once.
		 */
		public var targetLife:Number;

		/**
		 * setting the curLife will NOT show an instaneous change. the targetLife will
		 * just ease to this value. set both curLife and targetLife for instant change.
		 */
		public var curLife:Number;
		public var maxLife:Number;

		/**
		 * disables life hits. (though this could be done by disabling hits in a larger system as well.
		 * this is separate from the hitWaitTime which temporarily disables hits by a separate mechanism.
		 */
		public var _hittable:Boolean = true;

		public var alive:Boolean = true;

		/**
		 * time to wait between successive hits. (invincibility time)
		 * a negative number or 0 means there is no hitResetTime.
		 */
		public var hitResetTime:Number = 2;

		/**
		 * internal timer that counts the hit reset time.
		 */
		public var _resetTimer:Number;

		/**
		 * internally used to indicate the hitTimer is counting down, although this could be tested by hitTimer > 0, but
		 * that's a bit messy.
		 */
		public var _resetting:Boolean;

		/**
		 * marked true when life is continuously draining. this is used to mark blinking and sound effects.
		 */
		public var draining:Boolean;

		/**
		 * regen is life regen rate as life per second.
		 * as a final parameter, you can optionally set a different starting life from the maximum value.
		 */
		public function Life( lifeMax:Number, regen:Number=0, lifeCur:Number=-1 ) {

			this.maxLife = lifeMax;
			if ( lifeCur > 0 && lifeCur != lifeMax ) {
				this.curLife = this.targetLife = lifeCur;
			} else {
				this.curLife = this.targetLife = lifeMax;
			}

			this.regenRate = regen;
			//this.onDie = new Signal( Entity );

		} //

		/**
		 * sets current and target life to the specified amount, without easing.
		 */
		public function setCurrentLife( newLife:Number ):void {

			this.curLife = this.targetLife = newLife;

		} //

		/**
		 * a drain hit drains continuously and doesn't trigger the hit rest timer.
		 */
		public function drainHit( loseAmt:Number ):void {

			if ( !this.hittable ) {
				return;
			}

			this.targetLife -= loseAmt;
			this.draining = true;

		} //

		/**
		 * forces the player to take damage even when on a reset timer, but not if dead or unhittable.
		 */
		public function forceHit( loseAmt:Number ):void {

			if ( this.alive && this._hittable ) {

				this.targetLife -= loseAmt;

			} //

		} //

		public function hit( loseAmt:Number=1 ):void {

			if ( !this.hittable ) {
				return;
			}

			this.targetLife -= loseAmt;
			if ( this.hitResetTime > 0 ) {
				this._resetTimer = this.hitResetTime;
				this._resetting = true;
			}

		} //

		/**
		 * won't change the alive setting automatically. you still need to do that yourself.
		 */
		public function heal( healAmt:Number ):void {

			this.targetLife += healAmt;
			if ( this.maxLife > 0 && this.targetLife > this.maxLife ) {
				this.targetLife = this.maxLife;
			}

		} //

		public function respawn( startLife:int = -1 ):void {

			if ( startLife > 0 ) {
				this.curLife = this.targetLife = startLife;
			}

			this.alive = true;
			this.waitReset();		// give some invincible time.

		} //

		/**
		 * call this function to trigger the hitReset, where you're invincible for the hitResetTime.
		 */
		public function waitReset():void {

			this._resetTimer = this.hitResetTime;
			this._resetting = true;
			this._hittable = false;

		} //

		public function set hittable( b:Boolean ):void {
			this._hittable = b;
		} //

		public function get hittable():Boolean {
			return ( this.alive && this._hittable && !this._resetting );
		}

	} // class
	
} // package