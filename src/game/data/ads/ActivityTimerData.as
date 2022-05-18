package game.data.ads
{
	public class ActivityTimerData
	{
		public var event : ActivityTimerDataEvent;
		public var started : Boolean = false; // flag that timer started (default to false)
		public var start : int = 0; // start time
		public var end : int = 0; // end time
		public var campaign : String; // campaign name
		public var choice : String = AdTrackingConstants.TRACKING_TOTAL_TIME; // tracking choice: "TotalTime"
		public var persist : Boolean = false; // If true, the event will *not* be removed from data on completion
		public var onlyTrackOnComplete : Boolean = false; // if true, event will not be tracked when it is killed before the 'end' event happens
	}
}