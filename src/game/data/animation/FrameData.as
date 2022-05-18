package game.data.animation
{

	/**
	 * ... FrameData contains the data for a single frame
	 * @author Bard McKinley
	 */
	public class FrameData
	{
		public var index:uint;
		public var label:String;
		private var _events:Vector.<FrameEvent>;	// TODO : Split array into timelineEvents & rigEvents arrays (possible more), then the systems would only process the relavant events

		public function FrameData()
		{	
			_events = new Vector.<FrameEvent>();
		}
		
		public function addEvent(event:FrameEvent):void
		{	
			_events.push(event);
		}
				
		public function get events():Vector.<FrameEvent> { return _events; }
	}	
}
