/**
 * Parses XML with skin data.
 */

package game.data.character
{	
	import game.components.entity.character.part.SkinPart;
	import game.util.DataUtils;	
	import game.util.SkinUtils;

	public class LookParser
	{			
		public static function parseChar(xml:XML):LookData
		{	
			// TODO :: shoudl include variant type in here as well
			
			var look:LookData = new LookData();
			
			if ( xml.hasOwnProperty(SkinUtils.GENDER) )
				look.applyAspect( new LookAspectData( SkinUtils.GENDER, 	DataUtils.getString(xml.gender) ) );
			if ( xml.hasOwnProperty(SkinUtils.SKIN_COLOR) )
				look.applyAspect( new LookAspectData( SkinUtils.SKIN_COLOR, DataUtils.getNumber(xml.skinColor) ) );
			if ( xml.hasOwnProperty(SkinUtils.HAIR_COLOR) )
				look.applyAspect( new LookAspectData( SkinUtils.HAIR_COLOR, DataUtils.getNumber(xml.hairColor) ) );
			if ( xml.hasOwnProperty(SkinUtils.EYE_STATE) )
				look.applyAspect( new LookAspectData( SkinUtils.EYE_STATE, 	DataUtils.getString(xml.eyeState) ) );
			if ( xml.hasOwnProperty(SkinUtils.EYES) )
				look.applyAspect( new LookAspectData( SkinUtils.EYES, 		DataUtils.getString(xml.eyes) ) );
			if ( xml.hasOwnProperty(SkinUtils.MARKS) )
				look.applyAspect( new LookAspectData( SkinUtils.MARKS, 		DataUtils.getString(xml.marks) ) );
			if ( xml.hasOwnProperty(SkinUtils.MOUTH) )
				look.applyAspect( new LookAspectData( SkinUtils.MOUTH,		DataUtils.getString(xml.mouth) ) );
			if ( xml.hasOwnProperty(SkinUtils.FACIAL) )
				look.applyAspect( new LookAspectData( SkinUtils.FACIAL, 	DataUtils.getString(xml.facial) ) );
			else
			{
				// RLH: use empty facial part so we can change facial parts after NPCs are created (so we can throw cake onto NPCs' faces)
				look.applyAspect( new LookAspectData( SkinUtils.FACIAL, 	SkinPart.EMPTY) );
			}
			if ( xml.hasOwnProperty(SkinUtils.HAIR) )
				look.applyAspect( new LookAspectData( SkinUtils.HAIR, 		DataUtils.getString(xml.hair) ) );
			if ( xml.hasOwnProperty(SkinUtils.PANTS) )
				look.applyAspect( new LookAspectData( SkinUtils.PANTS,		DataUtils.getString(xml.pants) ) );
			if ( xml.hasOwnProperty(SkinUtils.SHIRT) )
				look.applyAspect( new LookAspectData( SkinUtils.SHIRT,		DataUtils.getString(xml.shirt) ) );
			if ( xml.hasOwnProperty(SkinUtils.OVERPANTS) )
				look.applyAspect( new LookAspectData( SkinUtils.OVERPANTS,	DataUtils.getString(xml.overpants) ) );
			else
			{
				// RLH: use empty overpants part so we can change overpants parts after NPCs are created (for ad tranformations)
				look.applyAspect( new LookAspectData( SkinUtils.OVERPANTS, 	SkinPart.EMPTY) );
			}
			if ( xml.hasOwnProperty(SkinUtils.OVERSHIRT) )
				look.applyAspect( new LookAspectData( SkinUtils.OVERSHIRT,	DataUtils.getString(xml.overshirt) ) );
			else
				look.applyAspect( new LookAspectData( SkinUtils.OVERSHIRT,	SkinPart.EMPTY ) ); // rlh: need this so ad powers can change part
			if ( xml.hasOwnProperty(SkinUtils.ITEM) )
				look.applyAspect( new LookAspectData( SkinUtils.ITEM, 		DataUtils.getString(xml.item) ) );
			else
				look.applyAspect( new LookAspectData( SkinUtils.ITEM, 		SkinPart.EMPTY ) ); // rlh: need this so ad powers can change part
			if ( xml.hasOwnProperty(SkinUtils.ITEM2) )
				look.applyAspect( new LookAspectData( SkinUtils.ITEM2, 		DataUtils.getString(xml.item2) ) );
			if ( xml.hasOwnProperty(SkinUtils.PACK) )
				look.applyAspect( new LookAspectData( SkinUtils.PACK,		DataUtils.getString(xml.pack) ) );
			else
				look.applyAspect( new LookAspectData( SkinUtils.PACK,		SkinPart.EMPTY ) ); // rlh: need this so ad powers can change part
			
			if ( xml.hasOwnProperty(SkinUtils.BODY) )
				look.applyAspect( new LookAspectData( SkinUtils.BODY,		DataUtils.getString(xml.body) ) );
			if ( xml.hasOwnProperty(SkinUtils.HEAD) )
				look.applyAspect( new LookAspectData( SkinUtils.HEAD,		DataUtils.getString(xml.head) ) );
			
			// pet look
			if ( xml.hasOwnProperty(SkinUtils.TAIL) )
				look.applyAspect( new LookAspectData( SkinUtils.TAIL,		DataUtils.getString(xml.tail) ) );
			if ( xml.hasOwnProperty(SkinUtils.PAW1) )
				look.applyAspect( new LookAspectData( SkinUtils.PAW1,		DataUtils.getString(xml.paw1) ) );
			if ( xml.hasOwnProperty(SkinUtils.PAW2) )
				look.applyAspect( new LookAspectData( SkinUtils.PAW2,		DataUtils.getString(xml.paw2) ) );
			if ( xml.hasOwnProperty(SkinUtils.PAW3) )
				look.applyAspect( new LookAspectData( SkinUtils.PAW3,		DataUtils.getString(xml.paw3) ) );
			if ( xml.hasOwnProperty(SkinUtils.PAW4) )
				look.applyAspect( new LookAspectData( SkinUtils.PAW4,		DataUtils.getString(xml.paw4) ) );
			if ( xml.hasOwnProperty(SkinUtils.CALF1) )
				look.applyAspect( new LookAspectData( SkinUtils.CALF1,		DataUtils.getString(xml.calf1) ) );
			if ( xml.hasOwnProperty(SkinUtils.CALF2) )
				look.applyAspect( new LookAspectData( SkinUtils.CALF2,		DataUtils.getString(xml.calf2) ) );
			if ( xml.hasOwnProperty(SkinUtils.CALF3) )
				look.applyAspect( new LookAspectData( SkinUtils.CALF3,		DataUtils.getString(xml.calf3) ) );
			if ( xml.hasOwnProperty(SkinUtils.CALF4) )
				look.applyAspect( new LookAspectData( SkinUtils.CALF4,		DataUtils.getString(xml.calf4) ) );
			if ( xml.hasOwnProperty(SkinUtils.THIGH1) )
				look.applyAspect( new LookAspectData( SkinUtils.THIGH1,		DataUtils.getString(xml.thigh1) ) );
			if ( xml.hasOwnProperty(SkinUtils.THIGH2) )
				look.applyAspect( new LookAspectData( SkinUtils.THIGH2,		DataUtils.getString(xml.thigh2) ) );
			if ( xml.hasOwnProperty(SkinUtils.THIGH3) )
				look.applyAspect( new LookAspectData( SkinUtils.THIGH3,		DataUtils.getString(xml.thigh3) ) );
			if ( xml.hasOwnProperty(SkinUtils.THIGH4) )
				look.applyAspect( new LookAspectData( SkinUtils.THIGH4,		DataUtils.getString(xml.thigh4) ) );
			
			// hands can be set as a pair
			if ( xml.hasOwnProperty("hands") )
			{
				look.applyAspect( new LookAspectData( SkinUtils.HAND1,		DataUtils.getString(xml.hands) ) );
				look.applyAspect( new LookAspectData( SkinUtils.HAND2,		DataUtils.getString(xml.hands) ) );
			}
			else
			{
				if ( xml.hasOwnProperty(SkinUtils.HAND1) )
					look.applyAspect( new LookAspectData( SkinUtils.HAND1,		DataUtils.getString(xml.hand1) ) );
				if ( xml.hasOwnProperty(SkinUtils.HAND1) )
					look.applyAspect( new LookAspectData( SkinUtils.HAND2,		DataUtils.getString(xml.hand2) ) );
			}
			
			// feet can be set as a pair
			if ( xml.hasOwnProperty("feet") )
			{
				look.applyAspect( new LookAspectData( SkinUtils.FOOT1,		DataUtils.getString(xml.feet) ) );
				look.applyAspect( new LookAspectData( SkinUtils.FOOT2,		DataUtils.getString(xml.feet) ) );
			}
			else
			{
				if ( xml.hasOwnProperty(SkinUtils.FOOT1) )
					look.applyAspect( new LookAspectData( SkinUtils.FOOT1,		DataUtils.getString(xml.foot1) ) );
				if ( xml.hasOwnProperty(SkinUtils.FOOT2) )
					look.applyAspect( new LookAspectData( SkinUtils.FOOT2,		DataUtils.getString(xml.foot2) ) );
			}
			
			
			if ( xml.hasOwnProperty(SkinUtils.BODY) )
				look.applyAspect( new LookAspectData( SkinUtils.BODY,		DataUtils.getString(xml.body) ) );
			if ( xml.hasOwnProperty(SkinUtils.HEAD) )
				look.applyAspect( new LookAspectData( SkinUtils.HEAD,		DataUtils.getString(xml.head) ) );
			
			// hands can be set as a pair
			if ( xml.hasOwnProperty("hands") )
			{
				look.applyAspect( new LookAspectData( SkinUtils.HAND1,		DataUtils.getString(xml.hands) ) );
				look.applyAspect( new LookAspectData( SkinUtils.HAND2,		DataUtils.getString(xml.hands) ) );
			}
			else
			{
				if ( xml.hasOwnProperty(SkinUtils.HAND1) )
					look.applyAspect( new LookAspectData( SkinUtils.HAND1,		DataUtils.getString(xml.hand1) ) );
				if ( xml.hasOwnProperty(SkinUtils.HAND1) )
					look.applyAspect( new LookAspectData( SkinUtils.HAND2,		DataUtils.getString(xml.hand2) ) );
			}
			
			// feet can be set as a pair
			if ( xml.hasOwnProperty("feet") )
			{
				look.applyAspect( new LookAspectData( SkinUtils.FOOT1,		DataUtils.getString(xml.feet) ) );
				look.applyAspect( new LookAspectData( SkinUtils.FOOT2,		DataUtils.getString(xml.feet) ) );
			}
			else
			{
				if ( xml.hasOwnProperty(SkinUtils.FOOT1) )
					look.applyAspect( new LookAspectData( SkinUtils.FOOT1,		DataUtils.getString(xml.foot1) ) );
				if ( xml.hasOwnProperty(SkinUtils.FOOT2) )
					look.applyAspect( new LookAspectData( SkinUtils.FOOT2,		DataUtils.getString(xml.foot2) ) );
			}
			
			
			return(look);
		}
	}
}