package game.data.character
{	
	import flash.utils.Dictionary;
	
	import game.components.entity.character.Skin;
	import game.components.entity.character.part.SkinPart;
	import game.creators.entity.character.CharacterCreator;
	import game.util.DataUtils;
	import game.util.SkinUtils;
	
	public class LookData
	{
		public function LookData(xml:XML = null)
		{
			_lookAspectDatas = new Dictionary();
			if( xml != null ) 	{ parse( xml ); }
		}
		
		public function applyAspect( lookAspect:LookAspectData ):void
		{
			if( lookAspect )
			{
				if ( DataUtils.isValidStringOrNumber( lookAspect.value ) )
				{
					_lookAspectDatas[lookAspect.id] = lookAspect;
				}
			}
		}
		
		public function getAspect( id:String ):LookAspectData
		{
			return _lookAspectDatas[ id ] as LookAspectData;
		}
		
		public function getValue( id:String ):*
		{
			var lookAspect:LookAspectData = getAspect(id);
			if ( lookAspect != null )
			{
				return lookAspect.value;
			}
			
			return null;
		}
		
		public function setValue( id:String, value:* ):void
		{
			var lookAspect:LookAspectData = getAspect(id);
			if ( lookAspect != null )
			{
				if( DataUtils.isValidStringOrNumber( value ) )
				{
					lookAspect.value = value;
				}
			}
			else
			{
				applyAspect( new LookAspectData( id, value ));
			}
		}
		
		public function fillValue( id:String, value:* ):void
		{
			var lookAspect:LookAspectData = getAspect(id);
			if ( lookAspect == null )
			{
				applyAspect( new LookAspectData( id, value ));
			}
		}
		
		public function applyLook( 	gender:String = "", skinColor:Number = NaN, hairColor:Number = NaN, 
									eyeState:String = "", marks:String = "", mouth:String = "", 
									facial:String = "", hair:String = "", pants:String = "", shirt:String = "", 
									overpants:String = "", overshirt:String = "", item:String = "", pack:String = "", 
									eyes:String ="", item2:String="" ):void
		{
			if( DataUtils.validString(gender) ) 	{ applyAspect( new LookAspectData( SkinUtils.GENDER, 		DataUtils.getString(gender)) ); }
			if( !isNaN(skinColor) )					{ applyAspect( new LookAspectData( SkinUtils.SKIN_COLOR, 	skinColor) ); }
			if( !isNaN(hairColor) )					{ applyAspect( new LookAspectData( SkinUtils.HAIR_COLOR, 	hairColor) ); }
			if( DataUtils.validString(eyeState) ) 	{ applyAspect( new LookAspectData( SkinUtils.EYE_STATE, 	DataUtils.getString(eyeState)) ); }
			if( marks != "" ) 						{ applyAspect( new LookAspectData( SkinUtils.MARKS, 		DataUtils.getString(marks)) ); } 
			if( mouth != "" )						{ applyAspect( new LookAspectData( SkinUtils.MOUTH, 		DataUtils.getString(mouth)) ); }
			if( facial != "" )						{ applyAspect( new LookAspectData( SkinUtils.FACIAL, 		DataUtils.getString(facial)) ); }
			if( hair != "" )						{ applyAspect( new LookAspectData( SkinUtils.HAIR, 			DataUtils.getString(hair)) ); }
			if( pants != "" )						{ applyAspect( new LookAspectData( SkinUtils.PANTS, 		DataUtils.getString(pants)) ); }
			if( shirt != "" )						{ applyAspect( new LookAspectData( SkinUtils.SHIRT, 		DataUtils.getString(shirt)) ); }
			if( overpants != "" )					{ applyAspect( new LookAspectData( SkinUtils.OVERPANTS,		DataUtils.getString(overpants)) ); }
			if( overshirt != "" )					{ applyAspect( new LookAspectData( SkinUtils.OVERSHIRT, 	DataUtils.getString(overshirt)) ); }
			if( item != "" )						{ applyAspect( new LookAspectData( SkinUtils.ITEM, 			DataUtils.getString(item)) ); }
			if( pack != "" )						{ applyAspect( new LookAspectData( SkinUtils.PACK, 			DataUtils.getString(pack)) ); }
			if( eyes != "" )						{ applyAspect( new LookAspectData( SkinUtils.EYES, 			DataUtils.getString(eyes)) ); }
			if( item2 != "" )						{ applyAspect( new LookAspectData( SkinUtils.ITEM2, 		DataUtils.getString(item2)) ); }
		}

		/**
		 * Empty all non-essential aspects that haven't been specified
		 */
		public function emptyAllFill():void
		{
			//fillValue( SkinUtils.SKIN_COLOR, 	SkinPart.EMPTY );
			//fillValue( SkinUtils.HAIR_COLOR, 	SkinPart.EMPTY );
			//fillValue( SkinUtils.EYE_STATE, 	SkinPart.EMPTY );
			//fillValue( SkinUtils.MOUTH, 		SkinPart.EMPTY );
			//fillValue( SkinUtils.HAIR, 		SkinPart.EMPTY );
			//fillValue( SkinUtils.PANTS, 		SkinPart.EMPTY );
			//fillValue( SkinUtils.SHIRT, 		SkinPart.EMPTY );
			//fillValue( SkinUtils.EYES, 		SkinPart.EMPTY );
			fillValue( SkinUtils.MARKS, 		SkinPart.EMPTY );
			fillValue( SkinUtils.FACIAL, 		SkinPart.EMPTY );
			fillValue( SkinUtils.OVERPANTS, 	SkinPart.EMPTY );
			fillValue( SkinUtils.OVERSHIRT, 	SkinPart.EMPTY );
			fillValue( SkinUtils.ITEM, 			SkinPart.EMPTY );
			fillValue( SkinUtils.PACK, 			SkinPart.EMPTY );
			fillValue( SkinUtils.ITEM2, 		SkinPart.EMPTY );
		}
		
		/**
		 * Fills and merges appropriate aspects in order to apply the 'base' look passed.
		 * @param	look
		 * @param	isPet - add more parts to the pet look (more complete)
		 */
		public function applyBaseLook( look:LookData, isPet:Boolean = false ):void
		{
			applyAspect( look.getAspect( SkinUtils.GENDER ) );
			
			fillValue( SkinUtils.SKIN_COLOR, look.getValue( SkinUtils.SKIN_COLOR ) );
			fillValue( SkinUtils.HAIR_COLOR, look.getValue( SkinUtils.HAIR_COLOR ) );
			fillValue( SkinUtils.MOUTH, look.getValue( SkinUtils.MOUTH ) );
			fillValue( SkinUtils.SHIRT, look.getValue( SkinUtils.SHIRT ) );
			fillValue( SkinUtils.PANTS, look.getValue( SkinUtils.PANTS ) );
			fillValue( SkinUtils.HAIR, look.getValue( SkinUtils.HAIR ) );
			fillValue( SkinUtils.EYES, look.getValue( SkinUtils.EYES ) );
			
			if (isPet)
			{
				fillValue( SkinUtils.MARKS, look.getValue( SkinUtils.MARKS ) );
				fillValue( SkinUtils.TAIL, look.getValue( SkinUtils.TAIL ) );
				fillValue( SkinUtils.HEAD, look.getValue( SkinUtils.HEAD ) );
				fillValue( SkinUtils.BODY, look.getValue( SkinUtils.BODY ) );
				fillValue( SkinUtils.PAW1, look.getValue( SkinUtils.PAW1 ) );
				fillValue( SkinUtils.PAW2, look.getValue( SkinUtils.PAW2 ) );
				fillValue( SkinUtils.PAW3, look.getValue( SkinUtils.PAW3 ) );
				fillValue( SkinUtils.PAW4, look.getValue( SkinUtils.PAW4 ) );
				fillValue( SkinUtils.CALF1, look.getValue( SkinUtils.CALF1 ) );
				fillValue( SkinUtils.CALF2, look.getValue( SkinUtils.CALF2 ) );
				fillValue( SkinUtils.CALF3, look.getValue( SkinUtils.CALF3 ) );
				fillValue( SkinUtils.CALF4, look.getValue( SkinUtils.CALF4 ) );
				fillValue( SkinUtils.THIGH1, look.getValue( SkinUtils.THIGH1 ) );
				fillValue( SkinUtils.THIGH2, look.getValue( SkinUtils.THIGH2 ) );
				fillValue( SkinUtils.THIGH3, look.getValue( SkinUtils.THIGH3 ) );
				fillValue( SkinUtils.THIGH4, look.getValue( SkinUtils.THIGH4 ) );
			}
		}
		
		public function applySkin( skin:Skin, fromPermanent:Boolean = true ):void
		{
			var numAspects:uint = SkinUtils.LOOK_ASPECTS.length;
			var skinPart:SkinPart;
			var skinPartId:String;
			for (var i:int = 0; i < numAspects; i++) 
			{
				skinPartId = SkinUtils.LOOK_ASPECTS[i];
				skinPart = skin.getSkinPart( skinPartId );
				if( skinPart )
				{
					if( fromPermanent )
					{
						applyAspect( new LookAspectData( skinPartId, skinPart.permanent));
					}
					else
					{
						applyAspect( new LookAspectData( skinPartId, skinPart.value));
					}
				}
			}
		}
		
		public function duplicate():LookData
		{
			var duplicateLook:LookData = new LookData();
			duplicateLook.fill( this );
			duplicateLook.variant = variant;
			return duplicateLook
		}
		
		/**
		 * Passed LookData will overwrite existing LookAspectData or be added if not yet defined
		 * @param	skin
		 * @param	isPermanent
		 */
		public function merge( look:LookData ):LookData
		{
			if( look )
			{
				var thisLookAspect:LookAspectData;
				for each ( var mergingLookAspect:LookAspectData in look._lookAspectDatas )
				{
					thisLookAspect = getAspect(mergingLookAspect.id);
					
					if( thisLookAspect == null )
					{
						applyAspect( mergingLookAspect.duplicate() );
					}
					else
					{
						thisLookAspect.value = mergingLookAspect.value;
					}
				}
			}
			return this;
		}
		
		/**
		 * Passed LookData will only fill in LookAspectData that is not presently define
		 */
		public function fill( look:LookData ):void
		{
			for each ( var fillingLookAspect:LookAspectData in look._lookAspectDatas )
			{
				if( getAspect( fillingLookAspect.id ) == null )
				{
					applyAspect( fillingLookAspect.duplicate() );
				}
			}
		}
		
		/**
		 * Passed LookData will only fill in LookAspectData that is not presently define
		 */
		public function remove( look:LookData ):void
		{
			for each ( var removingLookAspect:LookAspectData in look._lookAspectDatas )
			{
				if( getAspect( removingLookAspect.id ) != null )
				{
					// Need to check for permanent, should really use Skin.revertRemoveLook
					removingLookAspect.value = SkinPart.EMPTY;
				}
			}
		}
		
		/**
		 * Remove/Replace a specific part value from look
		 */
		public function removeLookAspect( partType:String, partValue:*, replaceWithDefault:Boolean = true ):Boolean
		{
			var currentAspect:LookAspectData = getAspect( partType );
			if( getAspect( partType ) != null )
			{
				if( currentAspect.value == partValue )
				{
					if( replaceWithDefault )
					{
						currentAspect.value = SkinUtils.getDefaultPart( partType );
					}
					else
					{
						currentAspect.value = SkinPart.EMPTY;
					}
					return true;
				}
			}
			return false;
		}
		
		/**
		 * Makes any non-defined LookAspectData into a LookAspectData with a value of "empty"
		 */
		public function fillWithEmpty():void
		{
			var skinId:String;
			for (var i:int = 0; i < SkinUtils.LOOK_ASPECTS.length; i++) 
			{
				skinId = SkinUtils.LOOK_ASPECTS[i];
				if( getAspect( skinId ) == null )
				{
					applyAspect( new LookAspectData( skinId, SkinPart.EMPTY ) );
				}
			}
		}
		
		private function parse(xml:XML):void
		{	
			this.id = DataUtils.getString( xml.attribute("id") );
			// TODO :: should include variant type in here as well
			
			if ( xml.hasOwnProperty(SkinUtils.GENDER) )
				applyAspect( new LookAspectData( SkinUtils.GENDER, 		DataUtils.getString(xml.gender) ) );
			if ( xml.hasOwnProperty(SkinUtils.SKIN_COLOR) )
				applyAspect( new LookAspectData( SkinUtils.SKIN_COLOR, 	DataUtils.getNumber(xml.skinColor) ) );
			if ( xml.hasOwnProperty(SkinUtils.HAIR_COLOR) )
				applyAspect( new LookAspectData( SkinUtils.HAIR_COLOR, 	DataUtils.getNumber(xml.hairColor) ) );
			if ( xml.hasOwnProperty(SkinUtils.EYE_STATE) )
				applyAspect( new LookAspectData( SkinUtils.EYE_STATE, 	DataUtils.getString(xml.eyeState) ) );
			if ( xml.hasOwnProperty(SkinUtils.EYES) )
				applyAspect( new LookAspectData( SkinUtils.EYES, 		DataUtils.getString(xml.eyes) ) );
			if ( xml.hasOwnProperty(SkinUtils.MARKS) )
				applyAspect( new LookAspectData( SkinUtils.MARKS, 		DataUtils.getString(xml.marks) ) );
			if ( xml.hasOwnProperty(SkinUtils.MOUTH) )
				applyAspect( new LookAspectData( SkinUtils.MOUTH,		DataUtils.getString(xml.mouth) ) );
			if ( xml.hasOwnProperty(SkinUtils.FACIAL) )
				applyAspect( new LookAspectData( SkinUtils.FACIAL, 		DataUtils.getString(xml.facial) ) );
			if ( xml.hasOwnProperty(SkinUtils.HAIR) )
				applyAspect( new LookAspectData( SkinUtils.HAIR, 		DataUtils.getString(xml.hair) ) );
			if ( xml.hasOwnProperty(SkinUtils.PANTS) )
				applyAspect( new LookAspectData( SkinUtils.PANTS,		DataUtils.getString(xml.pants) ) );
			if ( xml.hasOwnProperty(SkinUtils.SHIRT) )
				applyAspect( new LookAspectData( SkinUtils.SHIRT,		DataUtils.getString(xml.shirt) ) );
			if ( xml.hasOwnProperty(SkinUtils.OVERPANTS) )
				applyAspect( new LookAspectData( SkinUtils.OVERPANTS,	DataUtils.getString(xml.overpants) ) );
			if ( xml.hasOwnProperty(SkinUtils.OVERSHIRT) )
				applyAspect( new LookAspectData( SkinUtils.OVERSHIRT,	DataUtils.getString(xml.overshirt) ) );
			if ( xml.hasOwnProperty(SkinUtils.ITEM) )
				applyAspect( new LookAspectData( SkinUtils.ITEM, 		DataUtils.getString(xml.item) ) );
			if ( xml.hasOwnProperty(SkinUtils.ITEM2) )
				applyAspect( new LookAspectData( SkinUtils.ITEM2, 		DataUtils.getString(xml.item2) ) );
			if ( xml.hasOwnProperty(SkinUtils.PACK) )
				applyAspect( new LookAspectData( SkinUtils.PACK,		DataUtils.getString(xml.pack) ) );
			
			// pets
			if ( xml.hasOwnProperty(SkinUtils.OVERBODY) )
				applyAspect( new LookAspectData( SkinUtils.OVERBODY,	DataUtils.getString(xml.overbody) ) );
			if ( xml.hasOwnProperty(SkinUtils.TAIL) )
				applyAspect( new LookAspectData( SkinUtils.TAIL,		DataUtils.getString(xml.tail) ) );
			if ( xml.hasOwnProperty(SkinUtils.HEAD) )
				applyAspect( new LookAspectData( SkinUtils.HEAD,		DataUtils.getString(xml.head) ) );
			if ( xml.hasOwnProperty(SkinUtils.BODY) )
				applyAspect( new LookAspectData( SkinUtils.BODY,		DataUtils.getString(xml.body) ) );
			if ( xml.hasOwnProperty(SkinUtils.PAW1) )
				applyAspect( new LookAspectData( SkinUtils.PAW1,		DataUtils.getString(xml.paw1) ) );
			if ( xml.hasOwnProperty(SkinUtils.PAW2) )
				applyAspect( new LookAspectData( SkinUtils.PAW2,		DataUtils.getString(xml.paw2) ) );
			if ( xml.hasOwnProperty(SkinUtils.PAW3) )
				applyAspect( new LookAspectData( SkinUtils.PAW3,		DataUtils.getString(xml.paw3) ) );
			if ( xml.hasOwnProperty(SkinUtils.PAW4) )
				applyAspect( new LookAspectData( SkinUtils.PAW4,		DataUtils.getString(xml.paw4) ) );
			if ( xml.hasOwnProperty(SkinUtils.CALF1) )
				applyAspect( new LookAspectData( SkinUtils.CALF1,		DataUtils.getString(xml.calf1) ) );
			if ( xml.hasOwnProperty(SkinUtils.CALF2) )
				applyAspect( new LookAspectData( SkinUtils.CALF2,		DataUtils.getString(xml.calf2) ) );
			if ( xml.hasOwnProperty(SkinUtils.CALF3) )
				applyAspect( new LookAspectData( SkinUtils.CALF3,		DataUtils.getString(xml.calf3) ) );
			if ( xml.hasOwnProperty(SkinUtils.CALF4) )
				applyAspect( new LookAspectData( SkinUtils.CALF4,		DataUtils.getString(xml.calf4) ) );
			if ( xml.hasOwnProperty(SkinUtils.THIGH1) )
				applyAspect( new LookAspectData( SkinUtils.THIGH1,		DataUtils.getString(xml.thigh1) ) );
			if ( xml.hasOwnProperty(SkinUtils.THIGH2) )
				applyAspect( new LookAspectData( SkinUtils.THIGH2,		DataUtils.getString(xml.thigh2) ) );
			if ( xml.hasOwnProperty(SkinUtils.THIGH3) )
				applyAspect( new LookAspectData( SkinUtils.THIGH3,		DataUtils.getString(xml.thigh3) ) );
			if ( xml.hasOwnProperty(SkinUtils.THIGH4) )
				applyAspect( new LookAspectData( SkinUtils.THIGH4,		DataUtils.getString(xml.thigh4) ) );
			if ( xml.hasOwnProperty(SkinUtils.HAT) )
				applyAspect( new LookAspectData( SkinUtils.HAT,	DataUtils.getString(xml.hat) ) );
		}
		
		public function toString():String
		{
			var str:String = "\n"
			for each( var lookAspect:LookAspectData in _lookAspectDatas )
			{
				str += String( lookAspect.id + ": " + lookAspect.value + "\n" );
			}
			return str;
		}
		
		private var _lookAspectDatas:Dictionary;
		public function get lookAspects():Dictionary	{ return _lookAspectDatas; }
		public var variant:String = CharacterCreator.VARIANT_HUMAN;
		public var id:String;
	}
}
