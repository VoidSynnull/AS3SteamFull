package game.components
{
	import ash.core.Component;
	import flash.utils.Dictionary;
	
	public class EventData extends Component
	{
		public var allEventData:Dictionary;
		private var _event:String;
		private var _data:*;
		
		public function set event(eventName:String):void
		{
			if(_event != eventName)
			{
				_event = eventName;
				
				if(allEventData != null)
				{
					if(allEventData[eventName] != null)
					{
						_data = allEventData[_event];
					}
				}
				
			}
		}
		
		public function get event():String { return(_event); }
		public function get data():* { return(_data); }
	}
}