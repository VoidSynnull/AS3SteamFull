package game.data.ads
{
	public class ActivityTimerDataEvent
	{
		public var begin:Array; // the start event
		public var end:* = null; // the end event
		public var kill:* = null; // An event that should end this one other than the 'end' event.
		
		function ActivityTimerDataEvent()
		{
			
		}
	}
}