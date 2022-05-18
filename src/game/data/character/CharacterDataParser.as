/**
 * Parses XML with skin data.
 */

package game.data.character
{	
	import game.creators.entity.character.CharacterCreator;
	import game.data.animation.AnimationSequenceParser;
	import game.data.game.GameEvent;
	import game.util.CharUtils;
	import game.util.DataUtils;

	public class CharacterDataParser
	{			
		public function parse( charXml:XML ):CharacterData
		{	
			var charData:CharacterData = new CharacterData();
			
			var event:String = DataUtils.getString(charXml.attribute("event"));
			event = (event == null) ? GameEvent.DEFAULT : event;			// if no event is specified, make event default
			charData.event = event;
				 
			charData.id = DataUtils.getString(charXml.attribute("id"));											// the npc's unique id.
			
			charData.type = DataUtils.useString( charXml.attribute("type"), CharacterCreator.TYPE_NPC );		// type of character (player, npc, dummy), defaults to NPC
			
			charData.dynamicParts = DataUtils.getBoolean( charXml.attribute("dynamicParts") );		// type of character (player, npc, dummy), defaults to NPC
			
			charData.bitmap = (charXml.hasOwnProperty("bitmap")) ? DataUtils.getString(charXml.bitmap) : null; 	// path to external asset defining NPC, serves as flag as well
			
			charData.movieClip = (charXml.hasOwnProperty("movieClip")) ? DataUtils.getString(charXml.movieClip) : null; 	// path to external asset defining NPC, serves as flag as well

			charData.variant = DataUtils.useString( charXml.attribute("variant"), CharacterCreator.VARIANT_HUMAN );	// variant of character ( human, creature, head, etc. )
			
			// AnimationSequence, if null animation is motion controlled 
			charData.animSequence = (charXml.hasOwnProperty("animations")) ? AnimationSequenceParser.parse( XML(charXml.animations)) : null;

			// Starting position of npc
			charData.position = (charXml.hasOwnProperty("position")) ? DataUtils.getPoint(charXml.position) : null;
			
			// starting direction of npc
			charData.direction = (charXml.hasOwnProperty("direction")) ? DataUtils.getString(charXml.direction) : CharUtils.DIRECTION_LEFT;
			
			// ignore depth of npc
			charData.ignoreDepth = (charXml.hasOwnProperty("ignoreDepth")) ? DataUtils.getBoolean(charXml.ignoreDepth) : false;
			
			// check if costumizable
			charData.costumizable = (charXml.hasOwnProperty("costumizable")) ? DataUtils.getBoolean(charXml.costumizable) : true;
			
			// scale of character, if not specified uses scale from rigDefault.xml
			charData.scale = (charXml.hasOwnProperty("scale")) ? DataUtils.getNumber(charXml.scale) : NaN;
			
			charData.lineThickness = (charXml.hasOwnProperty("lineThickness")) ? DataUtils.getNumber(charXml.lineThickness) : 0;
			charData.noDarken = (charXml.hasOwnProperty("noDarken")) ? DataUtils.getBoolean(charXml.noDarken) : false;
			
			// The skin to be used on an npc
			// TODO :: Should respect skin defined by the variant
			charData.look = (charXml.hasOwnProperty("skin")) ? LookParser.parseChar( XML(charXml.skin)) : null;
			
			if(charXml.hasOwnProperty("skin"))
			{
				if(DataUtils.getBoolean(charXml.skin.attribute("random")))
				{
					var gender:String = DataUtils.getString(charXml.skin.gender);
					if(!_partDefaults) _partDefaults = new PartDefaults();
					charData.look = _partDefaults.randomLookData(charData.look,gender);
				}
			}
			
			// A rectangle that determines how far an npc can wander around while idle.
			charData.range = (charXml.hasOwnProperty("range")) ? DataUtils.getPoint(charXml.range) : null;
			
			// whetehr character faces speaker when talking or talked to.
			charData.faceSpeaker = DataUtils.useBoolean(charXml.faceSpeaker, true);
																		
			// proximity trigger
			charData.proximity = (charXml.hasOwnProperty("proximity")) ? DataUtils.getNumber(charXml.proximity) : -1;
			
			// optional unique talking mouth
			charData.talkMouth = (charXml.hasOwnProperty("talkMouth")) ? DataUtils.getString(charXml.talkMouth) : null;
			return 	charData;														
		}
		
		private var _partDefaults:PartDefaults;
	}
}