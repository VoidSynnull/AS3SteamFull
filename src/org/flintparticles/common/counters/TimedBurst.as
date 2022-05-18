
package org.flintparticles.common.counters
{
	import org.flintparticles.common.emitters.Emitter;		

	/**
	 * The Pulse counter causes the emitter to emit groups of particles at a regular
	 * interval.
	 */
	public class TimedBurst implements Counter
	{
		private var _timeToNext:Number = 0;
		private var _period:Number;
		private var _rate:Number;
		private var _running:Boolean;
		private var _interval:Number;
		private var _on:Boolean;
		private var _rateDelay:Number = 0;
		
		/**
		 * emit for a fix time, wait, then repeat
		 */
		public function TimedBurst(interval:Number = 1, period:Number = 1, rate:Number = 0 )
		{
			_running = false;
			_rate = rate;
			_period = period;
			_interval = interval;
		}
		
		/**
		 * Stops the emitter from emitting particles
		 */
		public function stop():void
		{
			_running = false;
		}
		
		/**
		 * Resumes the emitter after a stop
		 */
		public function resume():void
		{
			_running = true;
		}
		
		/**
		 * The time, in seconds, between each pulse.
		 */
		public function get period():Number
		{
			return _period;
		}
		public function set period( value:Number ):void
		{
			_period = value;
		}
		
		/**
		 * length of pulse.
		 */
		public function get interval():Number
		{
			return _interval;
		}
		public function set interval( value:Number ):void
		{
			_interval = value;
		}
		
		/**
		 * The number of particles to emit at each pulse.
		 */
		public function get quantity():uint
		{
			return _rate;
		}
		public function set quantity( value:uint ):void
		{
			_rate = value;
		}
		
		/**
		 * Initilizes the counter. Returns 0 to indicate that the emitter should 
		 * emit no particles when it starts.
		 * 
		 * <p>This method is called within the emitter's start method 
		 * and need not be called by the user.</p>
		 * 
		 * @param emitter The emitter.
		 * @return 0
		 * 
		 * @see org.flintparticles.common.counters.Counter#startEmitter()
		 */
		public function startEmitter( emitter:Emitter ):uint
		{
			_running = true;
			_timeToNext = _period;
			return _rate;
		}
		
		/**
		 * Uses the time, period and quantity to calculate how many
		 * particles the emitter should emit now.
		 * 
		 * <p>This method is called within the emitter's update loop and need not
		 * be called by the user.</p>
		 * 
		 * @param emitter The emitter.
		 * @param time The time, in seconds, since the previous call to this method.
		 * @return the number of particles the emitter should create.
		 * 
		 * @see org.flintparticles.common.counters.Counter#updateEmitter()
		 */
		public function updateEmitter( emitter:Emitter, time:Number ):uint
		{
			if( !_running )
			{
				return 0;
			}
			var count:uint = 0;
			if(_on){
				_rateDelay -= time;
				if(_rateDelay <= 0){
					count += _rate;
					_rateDelay = 1/_rate;
				}
			}
			_timeToNext -= time;
			if(_timeToNext <= 0){
				if(_on){
					_on = false;
					_timeToNext = _interval;
				}
				else{
					_on = true;
					_timeToNext = _period;
				}
			}
			return count;
		}

		/**
		 * Indicates if the counter has emitted all its particles. For this counter
		 * this will always be false.
		 */
		public function get complete():Boolean
		{
			return false;
		}
		
		/**
		 * Indicates if the counter is currently emitting particles
		 */
		public function get running():Boolean
		{
			return _running;
		}
	}
}