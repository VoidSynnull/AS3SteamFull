/**
 * Parses XML with npc data.
 * 
 * Npc's can have a unique setup for any game event.  If no event is specified in npcs.xml, they will
 * 	only ever use that single setup as DEFAULT.
 */

package game.data.character
{	
	import flash.utils.Dictionary;
	
	import game.data.game.GameEvent;
	
	public class NpcParser
	{				 
		/**
		 * Builds out CharacterData for default and other events that an npc has a different setup for.
		 * Any data missing from the event-specific CharacterData is filled in from the default.
		 * @param	xml - xml containing all npc specifc data within the scene, including event varaints 
		 * @return 	Dictionary of (npc id as key)CharacterSceneData
		 */
		public function parse( xml:XML ):Dictionary
		{	
			var allCharEventData:Dictionary = new Dictionary(); // Dictionary of (npc id as key)Dictionaries of (event as key)NPCData
			var npcXMLs:XMLList = xml.children();
			var charData:CharacterData;
			
			if( !_charDataParser )	{ _charDataParser = new CharacterDataParser(); }
			
			// create all npcs CharacterData within scene
			for (var i:uint = 0; i < npcXMLs.length(); i++)
			{	
				// check for displayType attribute first, to determine parser
				charData = _charDataParser.parse( npcXMLs[i] );
				
				if(allCharEventData[charData.id] == null)
				{
					allCharEventData[charData.id] = new CharacterSceneData(charData.id);
				}

				CharacterSceneData(allCharEventData[charData.id]).addCharData( charData );
			}
			
			// fill non-default CharacterData with default CharacterData, fills in any data that was not defined
			for each( var nextCharSceneData:CharacterSceneData in allCharEventData)	
			{
				nextCharSceneData.fillAllByEvent( GameEvent.DEFAULT );
			}
			
			return(allCharEventData);
		}
		
		private var _charDataParser:CharacterDataParser;
	}
}