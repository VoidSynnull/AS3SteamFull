package game.systems
{
	import ash.core.Engine;
	import ash.core.NodeList;
	import ash.core.System;
	import ash.tools.ListIteratingSystem;
	
	import game.nodes.EventDataNode;

	public class EventDataUpdateSystem extends ListIteratingSystem
	{
		public function EventDataUpdateSystem():void
		{
			super(EventDataNode, updateNode);
		}
		
		override public function update(time:Number):void
		{
			if(event != _currentEvent)
			{
				_currentEvent = event;
				super.update(time);
			}
		}
		
		override public function removeFromEngine(systemManager:Engine):void
		{
			systemManager.releaseNodeList(EventDataNode);
			
			super.removeFromEngine(systemManager);
		}
		
		private function updateNode(node:EventDataNode, time:Number):void
		{			
			node.eventData.event = _currentEvent;
		}
		
		public var event:String;
		private var _currentEvent:String;
	}
}
