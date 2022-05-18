package game.components.hit
{
	import flash.utils.Dictionary;
	
	import ash.core.Component;
	import ash.core.Entity;
	
	import game.data.scene.DoorData;
	
	import org.osflash.signals.Signal;
	
	public class Door extends Component
	{
		public var data:DoorData;		// stores door relevant information, where doors leads
		public var allData:Dictionary;	// Dictionary of DoorData, using event as key
		public var open:Boolean;
		public var opened:Boolean;
		public var hitOpened:Boolean;
		
		public var opening:Signal = new Signal(Entity);
		
		public function eventTriggered(event:String, makeCurrent:Boolean = true, init:Boolean = false, removeEvent:String = null):void
		{
			if(this.allData != null)
			{
				var current:DoorData = this.allData[event];
				
				if(current != null)
				{
					data = current;
				}
			}
		}
	}
}
