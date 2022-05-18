package game.systems
{

	import game.components.Timer;
	import game.data.TimedEvent;
	import game.nodes.TimerNode;
	
	/**
	 * Manages timers and their TimedEvents.
	 * Meant to replace Timer class in AS3.
	 */
	public class TimerSystem extends GameSystem
	{
		public function TimerSystem()
		{
			super( TimerNode, updateNode )
			super._defaultPriority = SystemPriorities.update;
		}
		
		private function updateNode( node:TimerNode, time : Number):void
		{
			var timer:Timer = node.timer;
			
			if ( timer.active )
			{
				timer.active = false;				// set back to true if any of the TimedEvent are running, or have not yet been started
				
				if ( timer.timedEvents.length > 0 )
				{
					var timedEvent:TimedEvent;
					var i:int = 0;
					for ( i; i < timer.timedEvents.length; i++ )
					{
						if ( updateTimer( timer.timedEvents[i], time ) )
						{
							timer.active = true;	// as long as one of the TimeEvents is running, timer component remains active.
						}
						else						// if TimeEvents is no longer running once started, remove from timer component
						{
							timer.timedEvents.splice( i, 1 );
							i--;	
						}
					}
				}
			}
		}
		
		/**
		 * Updates TimedEvent, decrementing timer form counter.
		 * TimedEvent is only updated after it has been started, 
		 * if it has not been started it will return as true.
		 * Once started will return the TimedEvent's running state.
		 * @param	timedEvent
		 * @param	time
		 * @return
		 */
		private function updateTimer( timedEvent:TimedEvent, time : Number ):Boolean
		{
				if ( timedEvent.running )		// if TimedEvent has been started, update time counter
				{
					if( !timedEvent.countByUpdate )
					{
						timedEvent.counter -= time;
					}
					else
					{
						timedEvent.counter--;
					}
					
					if ( timedEvent.counter <= 0 )
					{
						timedEvent.fire();		// dispatches event, decrements repeatCount, determines if still running
					}
					return timedEvent.running	// after counter update return running state 
				}
				return true;					// if TimedEvent hasn't been started, return true
		}
	}
}
