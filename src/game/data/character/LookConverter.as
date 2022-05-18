package game.data.character
{
	import flash.net.SharedObject;
	
	import ash.core.Entity;
	
	import engine.ShellApi;
	import engine.util.Command;
	
	import game.components.entity.character.Skin;
	import game.components.entity.character.part.SkinPart;
	import game.data.ads.AdvertisingConstants;
	import game.data.character.part.PartKeyLibrary;
	import game.data.profile.ProfileData;
	import game.systems.entity.EyeSystem;
	import game.util.CharUtils;
	import game.util.SkinUtils;

	// TODO :: add special ability conversion
	public class LookConverter
	{
		public function LookConverter()
		{
		}
		
		/**
		 * Save look to the profile
		 * @param	lookData
		 */
		public function playerLookFromLookData( lookData:LookData, playerLook:PlayerLook = null ):PlayerLook
		{
			if( playerLook == null )	{ playerLook = new PlayerLook(); }
			
			if(lookData.getAspect( SkinUtils.GENDER ) != null)
			playerLook.gender 		= ( lookData.getAspect( SkinUtils.GENDER ).value == SkinUtils.GENDER_MALE ) ? 1 : 0;
			playerLook.skinColor 	= lookData.getValue( SkinUtils.SKIN_COLOR );
			playerLook.hairColor 	= lookData.getValue( SkinUtils.HAIR_COLOR );
			playerLook.eyeState 	= lookData.getValue( SkinUtils.EYE_STATE );
			playerLook.marks 		= lookData.getValue( SkinUtils.MARKS );
			playerLook.mouth 		= lookData.getValue( SkinUtils.MOUTH );
			playerLook.facial 		= lookData.getValue( SkinUtils.FACIAL );
			playerLook.hair 		= lookData.getValue( SkinUtils.HAIR );
			playerLook.pants 		= lookData.getValue( SkinUtils.PANTS );
			playerLook.shirt 		= lookData.getValue( SkinUtils.SHIRT );
			playerLook.overpants 	= lookData.getValue( SkinUtils.OVERPANTS );
			playerLook.overshirt 	= lookData.getValue( SkinUtils.OVERSHIRT );
			playerLook.item 		= lookData.getValue( SkinUtils.ITEM );
			playerLook.pack 		= lookData.getValue( SkinUtils.PACK );
			playerLook.eyes 		= lookData.getValue( SkinUtils.EYES );
			playerLook.item2 		= lookData.getValue( SkinUtils.ITEM2 );
			
			return playerLook;
		}
		
		/**
		 * Save look to the profile
		 * @param	lookData
		 */
		public function lookDataFromPlayerLook( playerLook:PlayerLook, lookData:LookData = null ):LookData
		{ 
			if( lookData == null )	{ lookData = new LookData(); }
			var gender:String = ( playerLook.gender == 1 ) ? SkinUtils.GENDER_MALE : SkinUtils.GENDER_FEMALE
			lookData.applyLook( gender, playerLook.skinColor, playerLook.hairColor, playerLook.eyeState, playerLook.marks, 
								playerLook.mouth, playerLook.facial, playerLook.hair, playerLook.pants, playerLook.shirt, 
								playerLook.overpants, playerLook.overshirt, playerLook.item, playerLook.pack, playerLook.eyes, playerLook.item2 );
			return lookData;
		}
		
		
		public function assertLookString( shellApi:ShellApi ):String 
		{
			var player:Entity = shellApi.player;
			if ( player && player.get(Skin)) 
			{
				return this.getLookString(player);
			} 
			else 
			{
				return this.getLookStringFromLookData( this.lookDataFromPlayerLook( shellApi.profileManager.active.look ));
			}
			
			trace( "Error :: LookConverter :: assertLookString : no look was found.");
			return "";
		}
		
		
		/**
		 * Creates a look string formatted for AS2 from character <code>Entity</code>.
		 * @param char
		 * @return 
		 * 
		 */
		public function getLookString( char:Entity ):String 
		{
			var lookData:LookData = SkinUtils.getLook( char );
			var lookString:String = "";
			lookString += SkinUtils.GENDER_FEMALE == lookData.getValue(SkinUtils.GENDER) ? '0' : '1';
			lookString += ',' + lookData.getValue(SkinUtils.SKIN_COLOR);
			lookString += ',' + lookData.getValue(SkinUtils.HAIR_COLOR);
			lookString += ',' + CharUtils.getPartColor(char, CharUtils.LEG_FRONT);
			
			//var eyes:Eyes = Rig( char.get(Rig)).getPart( CharUtils.EYES_PART ).get(Eyes);
			//var lidPercent:Number = ( eyes ) ? eyes.data.lidPercent : 100;
			//lookString += ',' + lidPercent.toString();
			
			lookString += ',' + String(100);
			lookString += ',' + eyeFrameFromEyeState( lookData.getValue(SkinUtils.EYE_STATE) );
			lookString += ',' + checkEmpty(lookData.getValue(SkinUtils.MARKS), false);
			lookString += ',' + lookData.getValue(SkinUtils.PANTS);
			lookString += ',4';		// lineWidth = ???
			lookString += ',' + lookData.getValue(SkinUtils.SHIRT);
			lookString += ',' + checkEmptyHair(lookData.getValue(SkinUtils.HAIR), false);
			lookString += ',' + lookData.getValue(SkinUtils.MOUTH);
			lookString += ',' + checkEmpty(lookData.getValue(SkinUtils.ITEM), false);
			lookString += ',' + checkEmpty(lookData.getValue(SkinUtils.PACK), false);
			lookString += ',' + checkEmpty(lookData.getValue(SkinUtils.FACIAL), false);
			lookString += ',' + checkEmpty(lookData.getValue(SkinUtils.OVERSHIRT), false);
			lookString += ',' + checkEmpty(lookData.getValue(SkinUtils.OVERPANTS), false);
			lookString += ',none:';	// specialAbilities = ???
			
			return lookString;
		}
		
		/**
		 * Creates a look stirng formatted for AS2 from <code>LookData</code>
		 * @param lookData
		 * @param char
		 * @return 
		 * 
		 */
		public function getLookStringFromLookData( lookData:LookData, char:Entity = null ):String 
		{
			var lookString:String = "";
			lookString += SkinUtils.GENDER_FEMALE == lookData.getValue(SkinUtils.GENDER) ? '0' : '1';
			lookString += ',' + lookData.getValue(SkinUtils.SKIN_COLOR);
			lookString += ',' + lookData.getValue(SkinUtils.HAIR_COLOR);
			
			if( char )
			{
				lookString += ',' + CharUtils.getPartColor(char, CharUtils.LEG_FRONT);
			}
			else
			{
				lookString += ',' + lookData.getValue(SkinUtils.SKIN_COLOR);
			}
			
			//var eyes:Eyes = Rig( char.get(Rig)).getPart( CharUtils.EYES_PART ).get(Eyes);
			//var lidPercent:Number = ( eyes ) ? eyes.data.lidPercent : 100;
			//lookString += ',' + lidPercent.toString();
			
			lookString += ',' + String(100);
			lookString += ',' + eyeFrameFromEyeState( lookData.getValue(SkinUtils.EYE_STATE) );
			lookString += ',' + checkEmpty(lookData.getValue(SkinUtils.MARKS), false);
			lookString += ',' + lookData.getValue(SkinUtils.PANTS);
			lookString += ',4';		// lineWidth = ???
			lookString += ',' + lookData.getValue(SkinUtils.SHIRT);
			lookString += ',' + checkEmptyHair(lookData.getValue(SkinUtils.HAIR), false);
			lookString += ',' + lookData.getValue(SkinUtils.MOUTH);
			lookString += ',' + checkEmpty(lookData.getValue(SkinUtils.ITEM), false);
			lookString += ',' + checkEmpty(lookData.getValue(SkinUtils.PACK), false);
			lookString += ',' + checkEmpty(lookData.getValue(SkinUtils.FACIAL), false);
			lookString += ',' + checkEmpty(lookData.getValue(SkinUtils.OVERSHIRT), false);
			lookString += ',' + checkEmpty(lookData.getValue(SkinUtils.OVERPANTS), false);
			lookString += ',none:';	// specialAbilities = ???
			
			return lookString;
		}
		
		/**
		 * Set AS2LSO with converted values from <code>LookData</code>.
		 */
		public function applyLookDataToAS2LSO( lookData:LookData, char:Entity, lso:SharedObject ):void 
		{
			var lookString:String = "";
			lso.data.gender = SkinUtils.GENDER_FEMALE == lookData.getValue(SkinUtils.GENDER) ? '0' : '1';
			lso.data.skinColor = lookData.getValue(SkinUtils.SKIN_COLOR);
			lso.data.hairColor = lookData.getValue(SkinUtils.HAIR_COLOR);
			if( char != null )	{ lso.data.lineColor = CharUtils.getPartColor(char, CharUtils.LEG_FRONT); }
			lso.data.marksFrame = checkEmpty(lookData.getValue(SkinUtils.MARKS), false);
			lso.data.pantsFrame = lookData.getValue(SkinUtils.PANTS);
			lso.data.shirtFrame =  lookData.getValue(SkinUtils.SHIRT);
			lso.data.hairFrame = checkEmptyHair(lookData.getValue(SkinUtils.HAIR), false);
			lso.data.mouthFrame = lookData.getValue(SkinUtils.MOUTH);
			lso.data.itemFrame =  checkEmpty(lookData.getValue(SkinUtils.ITEM), false);
			lso.data.packFrame = checkEmpty(lookData.getValue(SkinUtils.PACK), false);
			lso.data.facialFrame =  checkEmpty(lookData.getValue(SkinUtils.FACIAL), false);
			lso.data.overshirtFrame =  checkEmpty(lookData.getValue(SkinUtils.OVERSHIRT), false);
			lso.data.overpantsFrame =  checkEmpty(lookData.getValue(SkinUtils.OVERPANTS), false);
		}
		
		/**
		 * Creates a new <code>LookData</code> from a player's look string of the form returned by <code>/get_embedInfo.php</code>.
		 * This form is arbitrarily referred to as <code>LookString0</code>, as there is apparently more than one format.
		 * <p>Here is a breakdown of the look string's contents:</p>
		 * <listing version="3.0">
		 look = 1,	// 0	gender			0 == girl, 1 == boy
		 16764057,	// 1	skinColor hex
		 5382915,	// 2	hairColor hex
		 13411194,	// 3	lineColor hex
		 46,		// 4	eyelids pos		lidPercent ?
		 3,			// 5	eyes frame		avatar_head.fla->eyes frame 1 - 28 ?	1:'squint',2:'casual',3:'open',4:'blink',10:'laugh',15:'cry',19:'angry',23:'closed',27:'mannequin',28:'zombie'
		 1,			// 6	marks frame		SWF ID: /avatarParts/marks/avatar_marks_&lt;ID&gt;.swf
		 3,			// 7	pants frame		SWF ID: /avatarParts/pants/avatar_pants_&lt;ID&gt;.swf
		 4,			// 8	lineWidth
		 3,			// 9	shirt frame		SWF ID
		 28,		// 10	hair frame		SWF ID
		 15,		// 11	mouth frame		avatar_head.fla->mouth frame 1 - 19
		 1,			// 12	item frame		SWF ID
		 1,			// 13	pack frame		SWF ID
		 1,			// 14	facial frame		SWF ID
		 1,			// 15	overshirt frame		SWF ID
		 1,			// 16	overpants frame		SWF ID
		 none:		// 17	special abilities array		abilityName:param0;param1;...^...
		 * </listing>
		 * @param ls0	An old-school player look string
		 * @return	A modern <code>LookData</code>
		 * 
		 */		
		public function lookDataFromLookString( ls0:String, lookData:LookData = null, partKeyLibrary:PartKeyLibrary = null, filterLimited:Boolean = false ):LookData 
		{
			if( lookData == null )	{ lookData = new LookData(); }
			var parts:Array = ls0.split(',');
			var gender:String = ( parts[0] == "1" )? SkinUtils.GENDER_MALE : SkinUtils.GENDER_FEMALE;	// 0 == female, 1 == male
			
			// if filtering "limited" from look string, then replace llmited parts with default parts
			if (filterLimited)
			{
				replaceLimited(parts, 6, SkinPart.EMPTY); // marks
				replaceLimited(parts, 14, SkinPart.EMPTY); // facial
				replaceLimited(parts, 11, "6"); // mouth (basic smile)
				replaceLimited(parts, 7, "6"); // default pants
				// if boy
				if (gender == SkinUtils.GENDER_MALE)
				{
					replaceLimited(parts, 10, "sears5"); // hair
					replaceLimited(parts, 9, "brandxpand_defaultboy"); // shirt					
				}
				else
				{
					// if girl
					replaceLimited(parts, 10, "sponsor_selenag"); // hair
					replaceLimited(parts, 9, "brandxpand_defaultgirl"); // shirt					
				}
				replaceLimited(parts, 16, SkinPart.EMPTY); // overpants
				replaceLimited(parts, 15, SkinPart.EMPTY); // overshirt
				replaceLimited(parts, 12, SkinPart.EMPTY); // item
				replaceLimited(parts, 13, SkinPart.EMPTY); // pack
			}

			if( partKeyLibrary )
			{
				lookData.applyLook(	gender, 				//gender
					parseInt(parts[1]), 					//skinColor
					parseInt(parts[2]), 					//hairColor
					eyeStateFromEyeFrame(parts[5]),			//eyeState
					partKeyLibrary.checkForLabel( SkinUtils.MARKS, checkEmpty( String(parts[6]).toLowerCase() ) ), 	//marks
					checkMouth(partKeyLibrary.checkForLabel( SkinUtils.MOUTH, String(parts[11]).toLowerCase() ) ), 	//mouth
					partKeyLibrary.checkForLabel( SkinUtils.FACIAL, checkEmpty( String(parts[14]).toLowerCase() ) ),	//facial
					partKeyLibrary.checkForLabel( SkinUtils.HAIR, checkEmptyHair( String(parts[10]).toLowerCase() ) ),//hair
					partKeyLibrary.checkForLabel( SkinUtils.PANTS, String(parts[7]).toLowerCase() ), 				//pants
					partKeyLibrary.checkForLabel( SkinUtils.SHIRT, String(parts[9]).toLowerCase() ), 				//shirt
					partKeyLibrary.checkForLabel( SkinUtils.OVERPANTS, checkEmpty( String(parts[16]).toLowerCase() ) ), 	//overpants
					partKeyLibrary.checkForLabel( SkinUtils.OVERSHIRT, checkEmpty( String(parts[15]).toLowerCase() ) ), 	//overshirt
					partKeyLibrary.checkForLabel( SkinUtils.ITEM, checkEmpty( String(parts[12]).toLowerCase() ) ), 	//item
					partKeyLibrary.checkForLabel( SkinUtils.PACK, checkEmpty( String(parts[13]).toLowerCase() ) ),	//pack
					'');	//eyes
			}
			else
			{
				lookData.applyLook(	gender, 								//gender
									parseInt(parts[1]), 					//skinColor
									parseInt(parts[2]), 					//hairColor
									eyeStateFromEyeFrame(parts[5]),			//eyeState
									checkEmpty( parts[6]), 	//marks
									checkMouth(parts[11]), 	//mouth
									checkEmpty(parts[14]),	//facial
									checkEmptyHair(parts[10]),//hair
									checkEmpty(parts[7]), 				//pants
									checkEmpty(parts[9]), 				//shirt
									checkEmpty(parts[16]), 	//overpants
									checkEmpty(parts[15]), 	//overshirt
									checkEmpty(parts[12]), 	//item
									checkEmpty(parts[13]),	//pack
									'');									//eyes
			}
			
			return lookData;
		}
		
		/**
		 * replace part string if has "limited" in it 
		 * @param parts
		 * @param index
		 * @param defaultPart
		 */
		private function replaceLimited(parts:Array, index:int, defaultPart:String):void
		{
			if (parts[index].toLowerCase().indexOf(AdvertisingConstants.AD_PATH_KEYWORD) != -1)
				parts[index] = defaultPart;
		}

		/**
		 * Converts/Assigns AS2 looks string to PlayerLook.
		 * Passing PartKeyLibrary converts frames in labels, if labels exist.
		 */
		public function playerLookFromLookString( shellApi:ShellApi, AS2lookString:String, playerLook:PlayerLook = null, partKeyLibrary:PartKeyLibrary = null, profile:ProfileData = null ):PlayerLook 
		{
			if( playerLook == null )	{ playerLook = new PlayerLook(); }
			var parts:Array = AS2lookString.split(',');
			playerLook.gender 		= parseInt(parts[0]);
			playerLook.skinColor 	= parseInt(parts[1]);
			playerLook.hairColor 	= parseInt(parts[2]);
			playerLook.eyeState 	= eyeStateFromEyeFrame(parts[5]);
			
			// if partKeyLibrary was included, check part values coming in as frame indexes that have matching labels, necessary for look strings coming in from AS2
			if( partKeyLibrary )
			{
				playerLook.marks 		= partKeyLibrary.checkForLabel( SkinUtils.MARKS, checkEmpty( String(parts[6]).toLowerCase() ) );
				playerLook.mouth 		= checkMouth(partKeyLibrary.checkForLabel( SkinUtils.MOUTH, String(parts[11]).toLowerCase() ) );
				playerLook.facial 		= partKeyLibrary.checkForLabel( SkinUtils.FACIAL, checkEmpty( String(parts[14]).toLowerCase() ) );
				playerLook.hair 		= partKeyLibrary.checkForLabel( SkinUtils.HAIR, checkEmptyHair( String(parts[10]).toLowerCase() ) );
				playerLook.pants 		= partKeyLibrary.checkForLabel( SkinUtils.PANTS, String(parts[7]).toLowerCase() );
				playerLook.shirt 		= partKeyLibrary.checkForLabel( SkinUtils.SHIRT, String(parts[9]).toLowerCase() );
				playerLook.overpants 	= partKeyLibrary.checkForLabel( SkinUtils.OVERPANTS, checkEmpty( String(parts[16]).toLowerCase() ) );
				playerLook.overshirt 	= partKeyLibrary.checkForLabel( SkinUtils.OVERSHIRT, checkEmpty( String(parts[15]).toLowerCase() ) );
				playerLook.item 		= partKeyLibrary.checkForLabel( SkinUtils.ITEM, checkEmpty( String(parts[12]).toLowerCase() ) );
				playerLook.pack 		= partKeyLibrary.checkForLabel( SkinUtils.PACK, checkEmpty( String(parts[13]).toLowerCase() ) );
			}
			else
			{
				playerLook.marks 		= checkEmpty( String(parts[6]).toLowerCase() );
				playerLook.mouth 		= checkMouth( String(parts[11]).toLowerCase() );
				playerLook.facial 		= checkEmpty( String(parts[14]).toLowerCase() );
				playerLook.hair 		= checkEmptyHair( String(parts[10]).toLowerCase() );
				playerLook.pants 		= String(parts[7]).toLowerCase();
				playerLook.shirt 		= String(parts[9]).toLowerCase();
				playerLook.overpants 	= checkEmpty( String(parts[16]).toLowerCase() );
				playerLook.overshirt 	= checkEmpty( String(parts[15]).toLowerCase() );
				playerLook.item 		= checkEmpty( String(parts[12]).toLowerCase() );
				playerLook.pack 		= checkEmpty( String(parts[13]).toLowerCase() );
			}
			playerLook.eyes 		= "";
			
			return playerLook;
		}
		
		public function playerLookFromJSON(json:String):PlayerLook
		{
			return PlayerLook.instanceFromJSON(json);
		}

		public function JSONFromPlayerLook(pl:PlayerLook):String {
			return pl.toJSONString();
		}
		
		//////////////////////////////////////////////////////////////////////////
		/////////////////////////// EMPTY CONVERSION /////////////////////////////
		//////////////////////////////////////////////////////////////////////////
		
		/**
		 * Convert 'empty' parts between AS2 and AS3.
		 * AS3 and AS2 manage 'empty' pars differently.  
		 * In AS3 if a part is empty its value is equal to 'empty'.
		 * In AS2 empty parts are actually swfs with no content, and are usually called '1', except in th ecase of haior where it is 'bald'.
		 * In AS2 the parts that use "1" as empty include:
		 * 		
		 * 		facial, item, marks, overpants, overshirt, pack
		 *
		 * The following do not have empty parts, and should never be empty:
		 * 		
		 * 		eyes, mouth, shirt, pants, 
		 */
		private function checkEmpty( value:String, fromAS2:Boolean = true ):* 
		{
			if(value != null)
				value.toLowerCase();
			if( fromAS2 )
			{
				if( value == "1" )
				{
					value = SkinPart.EMPTY;
				}
			}
			else
			{
				if( value == SkinPart.EMPTY )
				{
					value = "1";
				}
			}
			return value;
		}
		
		private function checkEmptyHair( value:String, fromAS2:Boolean = true ):* 
		{
			if( fromAS2 )
			{
				if( value == "bald" )
				{
					value = SkinPart.EMPTY;
				}
			}
			else
			{
				if( value == SkinPart.EMPTY )
				{
					value = "bald";
				}
			}
			return value;
		}
		
		//////////////////////////////////////////////////////////////////////////
		///////////////////////////// MOUTH CONVERSION ///////////////////////////
		//////////////////////////////////////////////////////////////////////////
		
		/**
		 * Checks for invalid valus coming from AS2 and returns suitable replacement.
		 */
		private function checkMouth( mouthId:String):String 
		{
			if( mouthId == "closed" )
			{
				return "2";
			}
			else
			{
				return mouthId;
			}
		}
		
		//////////////////////////////////////////////////////////////////////////
		///////////////////////////// EYE CONVERSION /////////////////////////////
		//////////////////////////////////////////////////////////////////////////
		
		private function eyeFrameFromEyeState(stateID:String):int 
		{
			// there are only 2 valid states, let's just check for them, otherwise default to squint
			if( stateID == EyeSystem.SQUINT )
			{
				return 1;
			}
			else if ( stateID == EyeSystem.OPEN )
			{
				return 3;
			}
			else
			{
				return 1
			}
		}
		
		
		private function eyeStateFromEyeFrame(frame:int):String 
		{
			// there are only 2 valid states, let's just check for them, otherwise default to squint
			if( frame == 1 )
			{
				return EyeSystem.SQUINT;
			}
			else if ( frame == 3 )
			{
				return EyeSystem.OPEN;
			}
			else
			{
				return EyeSystem.SQUINT;
			}
		}
		
		/*
		// NOTE : this whole dictionary thing just complicates stuff, 
		// since there are only 2 valid eye states for the player we just check for those. - Bard
		private function createEyeFrameDict():Dictionary 
		{
			if( !_eyeFrameDict )	{ _eyeFrameDict = new Dictionary(); }
			
			_eyeFrameDict[EyeSystem.SQUINT]	= 1;
			_eyeFrameDict[EyeSystem.CASUAL]	= 2;
			_eyeFrameDict[EyeSystem.OPEN]	= 3;
			_eyeFrameDict[EyeSystem.BLINK]	= 4;
			_eyeFrameDict[EyeSystem.LAUGH]	= 10;
			_eyeFrameDict[EyeSystem.CRY]	= 15;
			_eyeFrameDict[EyeSystem.ANGRY]	= 19;
			_eyeFrameDict[EyeSystem.CLOSED]	= 23;
			
			//_eyeFrameDict["mannequin"]		= 27;
			//_eyeFrameDict["zombie"]			= 28;
			
			return _eyeFrameDict;
		}
		*/
	}
}