package game.util
{	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.group.Group;
	import engine.util.Command;
	
	import game.components.entity.character.Profile;
	import game.components.entity.character.Rig;
	import game.components.entity.character.Skin;
	import game.components.entity.character.part.SkinPart;
	import game.components.entity.character.part.eye.Eyes;
	import game.components.timeline.Timeline;
	import game.data.character.LookAspectData;
	import game.data.character.LookConverter;
	import game.data.character.LookData;
	import game.data.character.PartDefaults;
	import game.data.character.PlayerLook;
	
	public class SkinUtils
	{	
		/**
		 * Apply LookData to a character's <code>Skin</code> component.
		 * @param character - needs to be a character Entity that contains a Skin component.
		 * @param lookData - the LookData to be applied, will only apply to parts defined within the LookData.
		 * @param isPermanent - whether applied values will be permanent.
		 * @param loadHandler - if given, will fire once all of the parts for provided look are loaded returns passed Enity.
		 */
		public static function applyLook( character:Entity, lookData:LookData, isPermanent:Boolean = true, loadHandler:Function = null ):void
		{
			var skin:Skin = character.get(Skin) as Skin; 
			if( skin )
			{
				skin.applyLook( lookData, isPermanent );	// merge new skin with existing skin
				
				// if loadHandler is given, setup Skin to track part loading
				if( loadHandler != null )
				{
					skin.partsLoading.length = 0;
					var handler:Function = Command.create( loadHandler, character );
					skin.lookLoadComplete.addOnce( handler ); 
					
					var rig:Rig = character.get( Rig ) as Rig;
					var partEntity:Entity;
					var skinPart:SkinPart;
					for each( var lookAspect:LookAspectData in lookData.lookAspects )	
					{
						// get skinPart associated with LookAspectData
						// only check parts within rig (don't check skincolor, hairColor, eyeState, etc.)
						partEntity = rig.getPart( lookAspect.id );	
						if( partEntity )
						{
							skinPart = partEntity.get( SkinPart );
							if ( skinPart )
							{
								if ( skinPart._invalidate )	// if skinPart is invalidated, has an asset to update 
								{
									skin.partsLoading.push( skinPart.id );
									skinPart.loaded.addOnce( skin.partLoaded );
								}
							}
						}
					}
					// if you are attempting to apply something you are already wearing
					if(skin.partsLoading.length == 0)
					{
						skin.lookLoadComplete.remove(handler);
						handler();
					}
				}
			}
		}
		
		/**
		 * Get a LookData based on the character's Skin values. 
		 * LookData returned is a new instance and not a reference to the character's LookData. 
		 * @param	character - needs to be a character Entity that contains a Skin component.
		 * @param	fromPermanent - true will retrieve permanent values, false will retrieve current values whether permanent or not.
		 * @return
		 */
		public static function getLook( character:Entity, fromPermanent:Boolean = true ):LookData
		{
			if( character != null )
			{
				var skin:Skin = character.get( Skin ) as Skin;
				if ( skin )
				{
					var lookData:LookData = new LookData();
					lookData.applySkin( skin, fromPermanent );
					return lookData;
				}
			}
			return null;
		}
		
		public static function getPlayerLook( group:Group, fromPermanent:Boolean = true ):LookData
		{
			var lookData:LookData = getLook(group.shellApi.player, fromPermanent);
			if(lookData == null)
			{
				var playerLook:PlayerLook = group.shellApi.profileManager.active.look;
				if( playerLook )
				{
					lookData = new LookConverter().lookDataFromPlayerLook(playerLook);
				}
			}
			
			return lookData;
		}
		
		public static function getLookAspect( character:Entity, skinPartId:String, fromPermanent:Boolean = true ):LookAspectData
		{
			var skin:Skin = character.get( Skin ) as Skin;
			if ( skin )
			{
				var skinPart:SkinPart = skin.getSkinPart( skinPartId );
				if( skinPart )
				{
					if( fromPermanent )
					{
						return new LookAspectData( skinPartId, skinPart.permanent);
					}
					else
					{
						return new LookAspectData( skinPartId, skinPart.value);
					}
				}
			}
			return null;
		}
		
		/**
		 * Revert/remove LookData from a character's <code>Skin</code> component.
		 */
		public static function removeLook( character:Entity, lookData:LookData, isPermanent:Boolean = true):void
		{
			// TODO :: make sure you required parts revert to defaults
			var skin:Skin = character.get( Skin );
			if( skin )
			{
				skin.revertRemoveLook( lookData, isPermanent);
			}
		}
		
		/**
		 * Save the player's look to the profile.
		 * @param	character
		 * @return
		 */
		public static function saveLook( character:Entity ):void
		{
			var profile:Profile = character.get( Profile ) as Profile;
			if ( profile )
			{
				var lookData:LookData = SkinUtils.getLook( character, true );
				if ( lookData )
				{
					profile.saveLook( lookData );
				}
			}
		}
		
		public static function getSkinPart( character:Entity, skinId:String ):SkinPart
		{
			return Skin(character.get(Skin)).getSkinPart(skinId);
		}
		
		public static function getSkinPartEntity( character:Entity, skinId:String ):Entity
		{
			var skin:Skin = Skin(character.get(Skin));
			if (skin == null)
				return null;
			else
				return skin.getSkinPartEntity(skinId);
		}
		
		public static function hasSkinValue( character:Entity, skinId:String, skinValue:* ):Boolean
		{
			return  SkinPart( Skin( character.get(Skin) ).getSkinPart(skinId) ).value == skinValue;
		}
		
		public static function hideSkinParts( character:Entity, skinIds:Array, hide:Boolean = true):void
		{
			for each (var id:String in skinIds) 
			{
				var partEnt:Entity = Skin(character.get(Skin)).getSkinPartEntity(id);
				if(partEnt){
					var disp:Display = partEnt.get(Display);
					if(disp){
						disp.visible = !hide;
					}
				}
			}
		}
		
		public static function isPartHidden( character:Entity, skinId:String):Boolean
		{
			var partEnt:Entity = Skin(character.get(Skin)).getSkinPartEntity(skinId);
			if(partEnt){
				var disp:Display = partEnt.get(Display);
				if(disp){
					return !disp.visible;
				}
			}
			return false;
		}
		
		/**
		 * Set part to have a new skin asset. 
		 * @param	character - needs to be a character Entity that contains a Skin component.
		 * @param	fromPermanent - true will retrieve permanent values, false will retrieve current values whether permanent or not.
		 * @param	handler - listens for SkinPart's loaded signal which returns a SkinPart component.
		 * @return
		 */
		public static function setSkinPart( character:Entity, skinId:String, value:*, permanent:Boolean = true, handler:Function = null, lock:Boolean = false ):Boolean
		{
			// RLH: added to scale specific NPCs
			if (skinId == "scale")
			{
				CharUtils.setScale(character,value * 0.36);
				return true;
			}
			
			// if mouth hidden then skip out
			if (skinId == MOUTH)
			{
				if (isPartHidden(character, skinId))
					return true;
			}
			
			var skinPart:SkinPart = Skin(character.get(Skin)).getSkinPart(skinId);
			if ( skinPart )
			{
				if( handler != null )
				{
					skinPart.loaded.addOnce( handler );	//returns SkinPart
				}
				skinPart.setValue( value, permanent );
				
				if( lock )
				{
					skinPart.lock = lock; 
				}
				// NOTE :: We lock the Timeline so any events applied to the Timeline will apply to the next part, not the current one.
				// Since it takes time to load parts we hold any Timeline events until the load is complete and then apply them.
				// This is also the case when value is same as current, as passing the same value will reset the part's Timeline.
				// Once the Timeline is reset the lock becomes false allowing Timeline events to be applied.
				// We do not want to lock the Timeline unless the SkinPart is actually invalidated.
				if( skinPart._invalidate )
				{
					var partEntity:Entity = Rig(character.get(Rig)).getPart(skinId);
					if( partEntity )
					{
						var timeline:Timeline = partEntity.get( Timeline );
						if( timeline )
						{
							timeline.lock = true;
						}
					}
				}
				
				return true;
			}
			else
			{
				trace( "Error :: SkinUtils :: setSkinPart :: No SkinPart with id: " + skinId + " has been defined." );
				//return false;
				// 
				// TODO :: Should we try to make the part?
				return true;
			}
		}
		
		public static function emptySkinPart( character:Entity, skinId:String, permanent:Boolean = true ):void
		{
			if ( skinId == SkinUtils.FACIAL || skinId == SkinUtils.ITEM || skinId == SkinUtils.ITEM2 || skinId == SkinUtils.MARKS || 
				skinId == SkinUtils.OVERPANTS || skinId == SkinUtils.OVERSHIRT || skinId == SkinUtils.PACK )
			{
				setSkinPart( character, skinId, SkinPart.EMPTY, permanent );
			}
			else
			{
				trace( "SkinUtils :: emptySkinPart :: cannot empty skin part of type: " + skinId + "." );
			}
		}
		
		/**
		 * Creates random LookData and applies it to a character's Skin.
		 * 
		 * @param Character: Character entity with a Skin component.
		 * @param Gender: An optional gender you want the Skin to pertain to.
		 * @return The generated LookData.
		 */
		public static function setRandomSkin(character:Entity, partDefaults:PartDefaults = null, gender:String = ""):LookData
		{
			if(!partDefaults) partDefaults = new PartDefaults();
			
			var lookData:LookData = new LookData();
			partDefaults.randomLookData(lookData, gender);
			
			character.get(Skin).applyLook(lookData);
			
			return lookData;
		}
		
		/**
		 * Creates random LookData and applies it to a character's Skin.
		 * 
		 * @param Character: Character entity with a Skin component.
		 * @param Gender: An optional gender you want the Skin to pertain to.
		 * @return The generated LookData.
		 */
		public static function setRandomSkinColors(character:Entity):void
		{
			var parts:PartDefaults = new PartDefaults();
			
			var skin:Skin = character.get(Skin);
			skin.getSkinPart(SkinUtils.HAIR_COLOR).setValue(ArrayUtils.getRandomElement(parts.hairColors));
			skin.getSkinPart(SkinUtils.SKIN_COLOR).setValue(ArrayUtils.getRandomElement(parts.skinColors));
		}
		
		/**
		 * Set the chars pupil state
		 * @param	character
		 * @param	data - can be a string specified within EyeSystem or an angle
		 * @return
		 */
		public static function setEyeStates( character:Entity, eyeState:String = "", pupilValue:* = null, permanent:Boolean = false ):Boolean
		{
			var rig:Rig = character.get( Rig );
			if( rig && rig.getPart( SkinUtils.EYES ))
			{
				var eyes:Eyes = Eyes(character.get(Rig).getPart(SkinUtils.EYES).get(Eyes));
				var success:Boolean = false;
				if( eyes )
				{
					if( DataUtils.validString( eyeState ) )
					{
						if( eyeState == SkinPart.PREVIOUS_VALUE )
						{
							eyes.state = eyes.state;	// don't change value, but apply just in case pupils are still manual
							//trace( " setEyeStates: set eyeState to previous: " + eyes.state );
						}
						else if( eyeState == SkinPart.DEFAULT_VALUE )
						{
							eyes.state = SkinUtils.getSkinPart( character, SkinUtils.EYE_STATE ).permanent;
							//trace( " setEyeStates: set eyeState to default: " + eyes.state );
						}
						else
						{
							eyes.state = eyeState;
							//trace( " setEyeStates: set eyeState to: " + eyes.state );
						}
						
						success = true;
					}
					
					if ( DataUtils.isValidStringOrNumber( pupilValue ) )
					{
						if( eyeState == SkinPart.PREVIOUS_VALUE )
						{
							eyes.pupilState = eyes.pupilState;	// don't change value, but apply just in case pupils are still manual
							//trace( " setEyeStates: set pupilState to previous: " + eyes.pupilState );
						}
						else
						{
							eyes.pupilState = pupilValue;
							//trace( " setEyeStates: set pupilState to: " + eyes.pupilState );
						}
						success = true;
					}
				}
				else
				{
					//trace( "Error :: SkinUtils :: setEyeStates :: Part does not contain an Eye component" );
				}
			}
			return success;
		}
		/**
		 * Get a look string back from the xml
		 * @param lookData: the lookData to convert
		 */
		public static function lookToString(lookData:LookData):String
		{
			var lookString:String = '0,0,0,0, "specific", ';
			
			for(var i:uint = 0; i < LOOK_ASPECTS.length; i++)
			{
				var aspect:LookAspectData = lookData.getAspect(LOOK_ASPECTS[i]);
				if(aspect != null)
				{
					if(Number(aspect.value))
						lookString +=  aspect.value;
					else if(aspect.value == "female")
						lookString += '0';
					else if(aspect.value == "male")
						lookString += '1';
					else
						lookString += '"' + aspect.value + '"';
				}
				else
				{
					if(LOOK_ASPECTS[i] == GENDER || LOOK_ASPECTS[i] == HAIR_COLOR || LOOK_ASPECTS[i] == SKIN_COLOR)
						lookString += 'a.'  + LOOK_ASPECTS[i];
					else if(LOOK_ASPECTS[i] == EYE_STATE)
						lookString += 'a.eyesFrame';
					else
						lookString += '1';
				}
				
				if(LOOK_ASPECTS[i] == GENDER)
					lookString += ', null';
				
				lookString += ", ";
			}
			
			// check and remove last comma
			if(lookString.length - 2 == lookString.lastIndexOf(','))
			{
				lookString = lookString.slice(0, lookString.length - 2);
			}
			
			return lookString;
		}
		
		public static function getDefaultPart( partType:String, gender:String = "" ):String
		{
			// TODO :: this should really be defined by xml and relate be specific to the variant
			var partId:String = "";
			switch(partType)
			{
				case SkinUtils.FACIAL:
				case SkinUtils.MARKS:
				case SkinUtils.OVERPANTS:
				case SkinUtils.OVERSHIRT:
				case SkinUtils.ITEM:
				case SkinUtils.ITEM2:
				case SkinUtils.PACK:
					partId = SkinPart.EMPTY;
					break;
				case SkinUtils.MOUTH:
					partId = "1";
					break;
				case SkinUtils.HAIR:
					if( gender == SkinUtils.GENDER_MALE ){
						partId = "wwprisoner";
					}else if( gender == SkinUtils.GENDER_FEMALE ){
						partId = "mthtownie02";
					}else{
						partId = "1";
					}
					break;
				case SkinUtils.SHIRT:
					partId = "2";
					break;
				case SkinUtils.PANTS:
					partId = "2";
					break;
				case SkinUtils.EYES:
					partId = "eyes";
					break;	
				default:
				{
					break;
				}
			}
			
			return partId;
		}
		
		// skin parts
		public static const GENDER:String 		= "gender";
		public static const SKIN_COLOR:String 	= "skinColor";
		public static const HAIR_COLOR:String 	= "hairColor";
		public static const EYE_STATE:String 	= "eyeState";
		
		public static const EYES:String 		= "eyes";
		public static const MARKS:String 		= "marks";
		public static const MOUTH:String 		= "mouth";
		public static const FACIAL:String 		= "facial";
		public static const HAIR:String 		= "hair";
		public static const PANTS:String 		= "pants";
		public static const SHIRT:String 		= "shirt";
		public static const OVERPANTS:String 	= "overpants";
		public static const OVERSHIRT:String 	= "overshirt";
		public static const ITEM:String 		= "item";
		public static const ITEM2:String 		= "item2";
		public static const PACK:String 		= "pack";
		
		// pet parts
		public static const TAIL:String			= "tail";
		public static const PAW1:String			= "paw1";
		public static const PAW2:String			= "paw2";
		public static const PAW3:String			= "paw3";
		public static const PAW4:String			= "paw4";
		public static const CALF1:String		= "calf1";
		public static const CALF2:String		= "calf2";
		public static const CALF3:String		= "calf3";
		public static const CALF4:String		= "calf4";
		public static const THIGH1:String		= "thigh1";
		public static const THIGH2:String		= "thigh2";
		public static const THIGH3:String		= "thigh3";
		public static const THIGH4:String		= "thigh4";
		public static const OVERBODY:String		= "overbody";
		public static const HAT:String			= "hat";
		
		// base parts
		public static const BODY:String 		= "body";
		public static const HEAD:String 		= "head";
		
		public static const FOOT1:String 		= "foot1";
		public static const FOOT2:String 		= "foot2";
		public static const HAND1:String 		= "hand1";
		public static const HAND2:String 		= "hand1";
		
		public static const GENDER_MALE:String 		= "male";
		public static const GENDER_FEMALE:String 	= "female";
		
		
		public static const LOOK_ASPECTS:Vector.<String> = Vector.<String>( ["gender", "skinColor", "hairColor", "eyeState", "eyes", "marks", "mouth", "facial", "hair", "pants", "shirt", "overpants", "overshirt", "item", "pack", "overbody", "hat"]);
		public static const PARTS:Vector.<String> = Vector.<String>( ["eyes", "marks", "mouth", "facial", "hair", "pants", "shirt", "overpants", "overshirt", "item", "pack", "overbody", "hat"]);
		public static const PARTS_REQUIRED:Vector.<String> = Vector.<String>( ["eyes", "mouth", "hair", "pants", "shirt"]);
	}
}
