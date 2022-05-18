package game.data.character
{
	import flash.utils.Dictionary;

	import game.util.DataUtils;

	/**
	 * Data class that contains Dictionary of CharacterData by event
	 * @author Bard
	 */
	public class CharacterSceneData
	{
		public var charId:String;
		public var isBitmap:Boolean = false;
		/** Dictionary of CharacterData using event as key */
		public var charDatasByEvent:Dictionary;
		/** Flag determining if a tool tip is created for character when character is created */
		public var addToolTip:Boolean = false;

		public function CharacterSceneData( charId:String = "", isCharBitmap:Boolean = false ):void
		{
			if ( DataUtils.validString( charId ) )
			{
				this.charId = charId;
			}
			this.isBitmap = isCharBitmap;
			charDatasByEvent = new Dictionary();
		}

		public function addCharData( charData:CharacterData ):void
		{
			charDatasByEvent[ charData.event ] = charData;
		}

		public function getCharData( event:String ):CharacterData
		{
			return charDatasByEvent[event];
		}

		/**
		 * Finds CharacterData related to event and merges its data into all other CharacterDatas.
		 * @param event
		 */
		public function fillAllByEvent( event:String ):void
		{
			var charDataMerge:CharacterData = charDatasByEvent[event];	// get default CharacterData

			if ( charDataMerge )			// if default exists...
			{
				for each( var charData:CharacterData in charDatasByEvent)
				{
					if ( charData.event != event )
					{
						charData.fillData( charDataMerge );	// merge CharacterData event with CharacterData default
					}
				}
			}
		}

		/**
		 * Set all CharaacterData to a type (Player, NPC, Dummy, etc. )
		 * @param type
		 */
		public function setType( type:String ):void
		{
			for each( var charData:CharacterData in charDatasByEvent )
			{
				charData.type = type;
			}
		}
	}
}
