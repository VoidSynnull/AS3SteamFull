package game.data
{
	import org.osflash.signals.Signal;
	public class TimedEvent
	{
		/**
		 * Data class to define timer information.
		 * Used by Timer compoent within TimerSystem.
		 * @param delay - in seconds
		 * @param repeatCount - number of times to repeat,  vlaue of zero will repeat infinitely
		 * @param handler - Function to call when timer fires.
		 * @param start - falg indicating if timer should start on creation, if false will need to start manually.
		 * 
		 */
		public function TimedEvent( delay:Number = 0, repeatCount:int = 0, handler:Function = null, start:Boolean = true )
		{
			signal = new Signal();
			this.delay = delay;
			this.repeatCount = repeatCount;
			
			if ( handler != null )
			{
				if ( repeatCount == 1 )
				{
					signal.addOnce( handler );
				}
				else
				{
					signal.add( handler );
				}
			}
			
			if ( start )
			{
				this.start();
			}
		}
		
		public var signal:Signal;
		public var counter:Number;					// counts down
		public var delay:Number;					// delay in seconds
		public var repeatCount:int = 0;				// number of times to repeat, if zero will repeat indefinitely
		public var countByUpdate:Boolean = false;	// uses update loops instead of seconds

		private var _currentCount:int;				// number of times it has dispatched
		public function get currentCount():int	{ return _currentCount; }
		
		public var _running:Boolean = false;		// if is start, remians false until start is called;
		public function get running():Boolean	{ return _running; }
		
		/////////////////////////////////////////////////////////////
		///////////////////////// COMMANDS //////////////////////////
		/////////////////////////////////////////////////////////////
		
		public function start():void
		{
			_running = true;
			counter = delay;
		}
		
		public function stop():void
		{
			_running = false;
		}
		
		public function fire():void
		{
			if ( repeatCount == 0 )	// if 0, then infinite repeat
			{
				counter = delay;
				signal.dispatch();
			}
			else
			{
				repeatCount--;
				_currentCount++;
				signal.dispatch();

				if ( repeatCount > 0 )
				{
					counter = delay;	
				}
				else
				{
					_running = false;
				}
			}
		}
	}
}