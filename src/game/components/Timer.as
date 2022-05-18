package game.components
{
	import ash.core.Component;
	import game.data.TimedEvent;
	
	public class Timer extends Component
	{
		public function Timer()
		{
			timedEvents = new Vector.<TimedEvent>();
		}
		
		public var timedEvents:Vector.<TimedEvent>;
		public var active:Boolean;					// active if contains TimerEvent, and TimerEvent is running
		
		public function addTimedEvent( timedEvent:TimedEvent, start:Boolean = false ):void
		{
			timedEvents.push( timedEvent );
			active = true;
			
			if ( start )
			{
				timedEvent.start();
			}
		}
	}
}
