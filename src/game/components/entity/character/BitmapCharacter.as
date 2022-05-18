package game.components.entity.character
{
	import ash.core.Component;
	
	import game.data.character.CharacterData;
	import game.data.character.CharacterSceneData;
	
	import org.osflash.signals.Signal;
	
	public class BitmapCharacter extends Component
	{
		public function BitmapCharacter()
		{
			loadComplete = new Signal();
		}
		
		public var loadComplete:Signal;					// dispatched when all of part assets have completed loading, passes Chararacter component
		
		public var type:String;							// Character type, Player, Npc, Dummy etc...
		public var variant:String;						// TODO :: not used, see if we can remove
		public var id:String;							// specific id for character, should be specific within each scene
		
		public var loading:Boolean = false;				// if currently loading assets
		public var active:Boolean = false;
		
		public var currentCharData:CharacterData;		
		public var nextCharData:CharacterData;	
		public var _charSceneData:CharacterSceneData;
		public var event:String;						// event character is currently defined by, EVENT_NONE if no events apply
		
		/**
		 * A handler listening to ShellApi's eventTrigger updates, receives latest events
		 * @param	event - recently triggered event
		 * @param   makeCurrent - should this be saved as the current data or simply triggered.
		 * @param	init - This is set to true ONLY for initial setup to get the latest event set to current after load and suppress triggering 'triggeredByEvent' data.
		 * @param   removeEvent - IF this event is getting removed, the current will need to get rest if it matches this event.      
		 */
		public function eventTriggered(event:String, makeCurrent:Boolean = true, init:Boolean = false, removeEvent:String = null):void
		{
			if(_charSceneData != null)
			{
				var currentData:CharacterData = _charSceneData.getCharData(event);
				
				if(currentData != null)	// check to see if there is corresponding data for this event
				{
					this.event = event;
					// do not update if this trigger is a result of an event removal
					if(removeEvent == null/* || removeEvent == this.currentCharData.event*/)
					{
						this.nextCharData = currentData;
					}
				}
			}
		}
	}
}

