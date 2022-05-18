package game.data.scene.hit
{
	import flash.utils.Dictionary;
	
	import ash.core.Component;
	
	public class HitAudioData extends Component
	{
		public var allEventAudio:Dictionary;
		public var currentActions:Dictionary = new Dictionary();
		
		public function eventTriggered(event:String, makeCurrent:Boolean = true, init:Boolean = false, removeEvent:String = null):void
		{
			if(this.allEventAudio != null)
			{
				var eventActions:Dictionary = this.allEventAudio[event];
				
				if(eventActions != null && makeCurrent)
				{
					for(var action:String in eventActions)
					{
						if(removeEvent == null || removeEvent == this.currentActions[action].event)
						{
							// only override new actions defined for this event.
							this.currentActions[action] = eventActions[action];
						}
					}
				}
			}
		}
	}
}