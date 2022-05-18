// Used by:
// Card 2448 using ability pop_follower_twin_girls
// Card 2455 using ability pop_follower_twin_boys
// Card 2540 using ability pop_follower_steve (llama follower)
// Card 2560 using ability pop_follower_gh_girl
// Card 2562 using ability pop_follower_boxtrolls
// Card 2586 using ability pop_follower_gold_fish
// Card 2592 using ability pop_follower_bay_max (hides NPC and plays random audio when clicked)
// Card 2611 using ability pop_follower_nightmuseum3 (caveman)
// Card 2631 using ability pop_follower_strange_magic (scaled down imp)
// Card 2651 using ability pop_follower_never_beast (creature scaled 200% with thick legs)
// Card 2666 using ability pop_follower_alligator (creature)
// Card 2672 using ability pop_follower_brady
// Card 2673 using ability pop_follower_mac (female)
// Card 2699 using ability pop_follower_mummy
// Card 2719 using ability pop_follower_ratatosk (creatue scaled 200% with random auto-dialog)
// Card 3449 using ability pop_follower_twin (store card with identical twin look)

// NOTES: eyesFrame has been changed to eyeState, eyeType has been changed to eyesFrame

// Known bug: when the overshirt part is a timeline animation (Lego 2 planty), the follower doesn't always load in browser
// OnFollowerLoaded doesn't trigger for some reason - must be a race condition created by converting timeline

package game.data.specialAbility.character
{
	import com.poptropica.AppConfig;
	
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.geom.Point;
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.net.SharedObject;
	import flash.net.URLRequest;
	
	import ash.core.Entity;
	import ash.core.NodeList;
	
	import engine.components.Display;
	import engine.components.Interaction;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	import engine.group.Scene;
	
	import game.components.entity.Dialog;
	import game.components.entity.Parent;
	import game.components.entity.character.Character;
	import game.components.entity.character.CharacterMotionControl;
	import game.components.entity.character.ColorSet;
	import game.components.render.Line;
	import game.components.smartFox.SFScenePlayer;
	import game.components.specialAbility.SpecialAbilityControl;
	import game.components.timeline.Timeline;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.ads.AdTrackingConstants;
	import game.data.character.CharacterData;
	import game.data.character.LookAspectData;
	import game.data.character.LookData;
	import game.data.scene.SceneType;
	import game.data.sound.SoundModifier;
	import game.data.specialAbility.SpecialAbility;
	import game.data.specialAbility.SpecialAbilityData;
	import game.managers.ScreenManager;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.scene.SceneSound;
	import game.scene.template.CharacterGroup;
	import game.systems.entity.EyeSystem;
	import game.systems.specialAbility.SpecialAbilityControlSystem;
	import game.ui.hud.Hud;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.PlatformUtils;
	import game.util.ProxyUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	
	/**
	 * Poptropican NPC follower behind avatar
	 * 
	 * Optional param:
	 * gender				String		Gender (male or female)
	 * skinColor			Uint		Skin color (default is black)
	 * hairColor			Uint		Hair color (default is pink flesh)
	 * eyesFrame			String		Eye frame ID (default is squint)
	 * mouthFrame			String		Mouth frame ID (default is 1)
	 * marksFrame			String		Marks frame ID
	 * facialFrame			String		Facial frame ID
	 * hairFrame			String		Hair frame ID (default is bald)
	 * shirtFrame			String		Shirt frame ID (bug - doesn't seem to carry over to follower) 
	 * pantsFrame			String		Pants frame ID
	 * packFrame			String		Pack frame ID
	 * itemFrame			String		Item frame ID
	 * overshirtFram		String		Overshirt frame ID
	 * overpantsFrame		String		Overpants frame ID
	 * avatarItemFrame		String		Item frame for avatar, not follower
	 * campaignName			String		Campaign name (only used when audio is enabled and user clicks on follower to trigger audio)
	 * isTwin				Boolean 	Follower is identical to avatar (default is false)
	 * noDarken				Boolean		Don't darken follower limbs  (default is false)
	 * scaleSize			Number		Scaling factor for follower (default is 0, which results in 1.0 for normal size)
	 * lineThickness		Number		Thickness of arms and legs (default is 0; variant limb.xml sets this to 4)
	 * hideNPC				String		NPC entity id to hide in scene
	 * hideParts			Array		Array of parts to hide
	 * autoDialog			String		Dialog string that triggers randomly
	 * randomDialog			Array		Array of random dialog strings
	 * randomClickDialog	Array		Array of random dialog strings to trigger when clicking follower
	 * dialogDelay			Number		Dialog delay for auto dialog (default is 0 for off)
	 * audioFile1,2,3,... 	Strings		Audio files to trigger
	 */
	public dynamic class AddPopFollower extends SpecialAbility
	{
		
		override public function init(node:SpecialAbilityNode):void
		{
			super.init( node );
			_node = node;
			id = data.id;
			if (this.data.id.indexOf("pets") != -1)
			{
				id = data.id.substr(5,data.id.length);
			}
			if(super.group is Scene)
			{
				// bypass all cut scenes or suppressed scenes
				if ( (Scene(super.group).sceneData.sceneType == SceneType.CUTSCENE) || (Scene(super.group).sceneData.suppressFollower) || shellApi.currentScene.groupPrefix.indexOf("common") > -1)
				{
					shellApi.logWWW("AddPopFollower: suppressed");
					trace("AddPopFollower: suppressed");
					super.suppressed = true;
				} else
				{
					//remove other pets
					for(var i:Number = 0; i<shellApi.currentProfile.specialAbilities.length;i++)
					{
						var ability:String = shellApi.currentProfile.specialAbilities[i];
						if(ability.indexOf("pets") != -1 && ability.indexOf(data.id) == -1 )
						{
							//var charGroup:CharacterGroup = super.group.getGroupById("characterGroup") as CharacterGroup;
							//charGroup.removeEntity(charGroup.getEntityById("popFollower"));
							shellApi.specialAbilityManager.removeSpecialAbilityFromPlayer(ability, true,true);
							overrideOldEntity = true;
							//var abi:SpecialAbilityData = shellApi.specialAbilityManager.getAbilityById(ability,true);
							//abi.removeFlag = true;
							
						}
					}
				}
			}
			
			
		}
		
		override public function activate( node:SpecialAbilityNode ):void
		{
			
			// if follower already loaded and special action button, then trigger
			if ((_npcFollower) && (_followerLoaded) && (_useSpecialActionBtn))
			{
				followerTrigger();
				return;
			}
			
			// if not suppressed and not active
			if (!super.data.isActive)
			{
				// if pet follower, then get custom data
				if (this.data.id.indexOf("pets") != -1)
				{
					_isPet = true;
					var petID:String = "pet" + _id;
					
					// need to store original look
					_origLook = {};
					// get all frame parts
					for (var part:String in conversionObj)
					{
						_origLook[part] = this["_" + part];
					}
					
					// check if pulled down database data for this session
					// if not pulled down, then get data from database the first time
					if (super.group.shellApi.pets[petID] == null)
					{
						trace("PetLook: get from database first time");
						super.group.shellApi.getUserField(petID, "", gotCustomLook, true);
					}
					else
					{
						// check profile by for pet id
						var customLook:Object = super.group.shellApi.profileManager.active.pets[petID];
						// if not found, then pull from database
						if (customLook == null)
						{
							trace("PetLook: get from database again");
							super.group.shellApi.getUserField(petID, "", gotCustomLook, true);
						}
						else
						{
							// using custom look from profile
							trace("PetLook: get from profile");
							gotCustomLook(customLook, false);
						}
					}
				}
				else
				{
					// if standard follower (not pet)
					trace("AddPopFollower: activate");
					shellApi.logWWW("AddPopFollower: activate");
					createFollower();
				}
			}
		}
		
		/**
		 * Gets and processes custom look for pet follower.
		 * @param look object
		 * @param fromDatabase whether look comes from database (versus profile)
		 */
		private function gotCustomLook(look:Object, fromDatabase:Boolean = true):void
		{
			// if from database, then save to profile
			if (fromDatabase)
			{
				var petID:String = "pet" + _id;
				
				// set flag that we have pulled down look from database
				super.group.shellApi.pets[petID] = true;
				
				// if no look, then set to empty object
				if (look == null)
					look = {};
				
				// save database look to profile
				super.group.shellApi.profileManager.active.pets["pet" + _id] = look;
				super.group.shellApi.profileManager.save();
			}
			
			// iterate through custom fields
			for (var name:String in look)
			{
				trace("PetLook: " + name + ":" + look[name]);
				// qpply to follower
				this["_" + name] = look[name];
			}
			
			// now ready to create follower
			createFollower();
		}
		
		private function createFollower():void
		{
			
			
			// if twin then get player look
			if( _isTwin )
				_look = SkinUtils.getPlayerLook(super.group);
			else
			{
				// setup look for follower
				_look = new LookData();
				
				// these two are reversed but have to keep for legacy reasons
				_look.applyAspect( new LookAspectData( SkinUtils.EYES, _eyesFrame ) ); // use eyesFrame to replace standard eyes
				_look.applyAspect( new LookAspectData( SkinUtils.EYE_STATE, _eyeState ) ); // eye state: open or squint or casual
				_look.applyAspect( new LookAspectData( SkinUtils.GENDER, _gender ) );
				_look.applyAspect( new LookAspectData( SkinUtils.HAIR_COLOR, _hairColor ) );
				_look.applyAspect( new LookAspectData( SkinUtils.SKIN_COLOR, _skinColor ) );
				_look.applyAspect( new LookAspectData( SkinUtils.FACIAL, _facialFrame ) );
				_look.applyAspect( new LookAspectData( SkinUtils.MOUTH, _mouthFrame ) );
				_look.applyAspect( new LookAspectData( SkinUtils.MARKS, _marksFrame ) );
				_look.applyAspect( new LookAspectData( SkinUtils.HAIR, _hairFrame ) );
				_look.applyAspect( new LookAspectData( SkinUtils.PANTS, _pantsFrame ) );
				_look.applyAspect( new LookAspectData( SkinUtils.SHIRT, _shirtFrame ) );
				_look.applyAspect( new LookAspectData( SkinUtils.PACK, _packFrame ) );
				_look.applyAspect( new LookAspectData( SkinUtils.ITEM, _itemFrame ) );
				_look.applyAspect( new LookAspectData( SkinUtils.OVERSHIRT, _overshirtFrame ) );
				_look.applyAspect( new LookAspectData( SkinUtils.OVERPANTS, _overpantsFrame ) );
				_look.applyAspect( new LookAspectData( SkinUtils.HEAD, _headFrame ) );
				_look.applyAspect( new LookAspectData( SkinUtils.BODY, _bodyFrame ) );
				_look.applyAspect( new LookAspectData("variant"));
				
				if (_isPet)
				{
					_look.applyAspect( new LookAspectData( SkinUtils.TAIL, _tailFrame ) );
					_look.applyAspect( new LookAspectData( SkinUtils.PAW1, _paw1Frame ) );
					_look.applyAspect( new LookAspectData( SkinUtils.PAW2, _paw2Frame ) );
					_look.applyAspect( new LookAspectData( SkinUtils.PAW3, _paw3Frame ) );
					_look.applyAspect( new LookAspectData( SkinUtils.PAW4, _paw4Frame ) );
					_look.applyAspect( new LookAspectData( SkinUtils.CALF1, _calf1Frame ) );
					_look.applyAspect( new LookAspectData( SkinUtils.CALF2, _calf2Frame ) );
					_look.applyAspect( new LookAspectData( SkinUtils.CALF3, _calf3Frame ) );
					_look.applyAspect( new LookAspectData( SkinUtils.CALF4, _calf4Frame ) );
					_look.applyAspect( new LookAspectData( SkinUtils.THIGH1, _thigh1Frame ) );
					_look.applyAspect( new LookAspectData( SkinUtils.THIGH2, _thigh2Frame ) );
					_look.applyAspect( new LookAspectData( SkinUtils.THIGH3, _thigh3Frame ) );
					_look.applyAspect( new LookAspectData( SkinUtils.THIGH4, _thigh4Frame ) );
					_look.applyAspect( new LookAspectData( SkinUtils.OVERBODY, _overbodyFrame ) );
					_look.applyAspect( new LookAspectData( SkinUtils.HAT, _hatFrame ) );
				}
			}
			shellApi.logWWW("AddPopFollower: create NPC with look: " + _look);
			trace("AddPopFollower: create NPC with look: " + _look);
			// NOTE: if you are not seeing changes to the special ability, you will need to push the xml file live
			
			// if audioFile1 parameter is listed, prepare to setup and load audio
			if ( _audioFile1 )
			{
				_useAudio = true;
				_audioFiles = new Array();
				_audioFilesLoaded = 0;
				_audioSounds = new Array();
				_audioLock = false;
				_audioInitialPlay = false;
				
				// get list of audio files
				var currentAudioFile:int = 1;
				var maxFiles:int = 4;
				while ( this["_audioFile" + currentAudioFile] )
				{
					_audioFiles.push(this["_audioFile" + currentAudioFile]);
					currentAudioFile++;
				}
				
				// load first file				
				loadNextAudioFile();
			}
			
			// create follower
			var charGroup:CharacterGroup = super.group.getGroupById("characterGroup") as CharacterGroup;
			
			// skip out if character group is null (can happen when scrolling quickly through store)
			if (charGroup == null)
			{
				shellApi.logWWW("AddPopFollower: no character group found");
				trace("AddPopFollower: no character group found");
				return;
			}
			
			// get scale and direction and position
			var charSpatial:Spatial = super.entity.get(Spatial);
			var xPos:Number = charSpatial.x;
			var yPos:Number = charSpatial.y;			
			var scaleX:Number = charSpatial.scaleX;
			var dir:int = 1;
			if (scaleX < 0)
				dir = -1;
			
			if(overrideOldEntity)
			{
				shellApi.currentScene.removeEntity(shellApi.currentScene.getEntityById("popFollower"));
			}
			trace("AddPopFollower: create and position: x: " + xPos + ", y: " + yPos);
			shellApi.logWWW("AddPopFollower: create and position: x: " + xPos + ", y: " + yPos);
			var character:Character = entity.get(Character);
			if(character && character.currentCharData.type == CharacterData.TYPE_DUMMY)
			{
				_look.applyAspect( new LookAspectData( SkinUtils.EYE_STATE, EyeSystem.OPEN_STILL ) ); // force to open still
				_npcFollower = charGroup.createDummy("popFollower"+super.shellApi.profileManager.active.login+(Math.random() * 1000).toString(), _look, dir == 1 ? "left" : "right", _variant, entity.get(Display).container, this, onDummyLoaded, false, NaN, "dummy", new Point(xPos + dir*70, yPos + 40));
			}
			else
			{
				if(super.entity.get(SFScenePlayer) != null)
				{
					var sfPlayer:SFScenePlayer = super.entity.get(SFScenePlayer);
					_npcFollower = charGroup.createDummy("popFollower" + sfPlayer.user.name, _look, dir == 1 ? "left" : "right", _variant, entity.get(Display).container, this, onDummyLoaded, false, NaN, "dummy", new Point(xPos + dir*70, yPos + 40));
				}
				else
				{
					
					_npcFollower = charGroup.createNpc("popFollower", _look, xPos + dir * 0.7 * _distance, yPos + 40, "left", _variant, null, onFollowerLoaded);
				}
			}
			
			// hide until loaded
			_npcFollower.get(Display).visible = false;
			
			// need this flip so follower faces in same direction as player
			_npcFollower.get(Spatial).scaleX = scaleX;
			
			// if needing to put item into avatar's hand, then do so
			if( _avatarItemFrame )
			{
				var lookAspect:LookAspectData = new LookAspectData( SkinUtils.ITEM, _avatarItemFrame); 
				_itemLookData = new LookData();
				_itemLookData.applyAspect( lookAspect );
				SkinUtils.applyLook( super.shellApi.player, _itemLookData, false );	
			}			
		}
		
		override public function update(node:SpecialAbilityNode, time:Number):void
		{
			// if follower loaded
			if((_npcFollower) && (_followerLoaded))
			{
				//shellApi.logWWW("AddPopFollower: update");
				// if twin and looks differ, then reapply look to follower
				if( (_isTwin) && (SkinUtils.getLook(_npcFollower) != SkinUtils.getLook(super.shellApi.player)) )
				{
					_look = SkinUtils.getPlayerLook(super.group);
					SkinUtils.applyLook(_npcFollower,_look);
				}
				
				// if replaced clip, then update clip based on follower
				if (_replacedClip)
				{
					_replacedClip.get(Spatial).x = _npcFollower.get(Spatial).x;
					_replacedClip.get(Spatial).y = _npcFollower.get(Spatial).y;
					if (_npcFollower.get(Spatial).scaleX > 0)
					{
						_replacedClip.get(Spatial).scaleX = 1;
						if(_flippablePart)
							_clip.flippable.gotoAndStop(1);
					}
					else
					{
						_replacedClip.get(Spatial).scaleX = -1;
						if(_flippablePart)
							_clip.flippable.gotoAndStop(2);
					}
					
					if(_animated)
					{
						if(_npcFollower.get(Motion).velocity.x != 0 && _playingAnimation == false)
						{
							Timeline(_replacedClip.get(Timeline)).paused = false;
							_playingAnimation = true;
						}
						if(_playingAnimation == true)
						{
							if(Timeline(_replacedClip.get(Timeline)).currentIndex == Timeline(_replacedClip.get(Timeline)).totalFrames - 1)
							{
								_playingAnimation = false;
								Timeline(_replacedClip.get(Timeline)).gotoAndPlay(2);
							}
						}
						if(_npcFollower.get(Motion).velocity.x == 0)
						{
							Timeline(_replacedClip.get(Timeline)).paused = true;
							_playingAnimation = false;
						}
					}
				}
			}
		}
		
		private function onDummyLoaded(charEntity:Entity = null):void
		{
			_followerLoaded = true;
			setActive( true );
			
			CharUtils.freeze(charEntity);
			DisplayUtils.moveToOverUnder(charEntity.get(Display).displayObject, entity.get(Display).displayObject, false);
			
			charEntity.get(Display).visible = true;
		}
		
		/**
		 * When follower loaded 
		 * @param charEntity
		 */
		private function onFollowerLoaded( charEntity:Entity = null):void
		{
			shellApi.logWWW("AddPopFollower: follower loaded");
			trace("AddPopFollower: follower loaded");
			_followerLoaded = true;
			super.setActive( true );
			
			// increase distance if scaling avatar
			if (_scaleSize > 1)
				_distance *= _scaleSize;
			
			// set behind player
			DisplayUtils.moveToOverUnder(charEntity.get(Display).displayObject, shellApi.player.get(Display).displayObject, false);
			
			// set follow
			if(super.entity.get(SFScenePlayer) != null)
			{
				//var user:User = super.shellApi.smartFox.userManager.getUserByName( super.entity.get(SFScenePlayer).user.name);	
				var charGroup:CharacterGroup = super.group.getGroupById("characterGroup") as CharacterGroup;
				var followEnt:Entity = charGroup.getEntityById(super.entity.get(SFScenePlayer).user.name);
				CharUtils.followEntity(_npcFollower, followEnt, new Point(_distance, 120));
				
			}
			else
				CharUtils.followEntity(_npcFollower, super.entity, new Point(_distance, 120));
			// scaling factor: 2 for web, mobile will be variable
			// 2 on mobile had pet skidding past the avatar
			var scalingFactor:Number = 2 * shellApi.viewportWidth / ScreenManager.GAME_WIDTH;
			CharacterMotionControl(_npcFollower.get(CharacterMotionControl)).scalingFactor = scalingFactor;
			
			//set limb width
			if(_lineThickness != 0)
			{
				var partList:Array = [CharUtils.LEG_FRONT, CharUtils.LEG_BACK, CharUtils.ARM_FRONT, CharUtils.ARM_BACK];
				for each (var part:String in partList)
				{
					var npcPart:Entity = CharUtils.getPart( _npcFollower, part );
					if (npcPart != null)
						npcPart.get(Line).lineWidth = _lineThickness;					
				}
			}
			
			// scale avatar if scale
			if (_scaleSize != 0)
				CharUtils.setScale(_npcFollower, _scaleSize * 0.36);
			
			// if using audio, then set up interaction
			if ( _useAudio )
			{
				// if user has loaded all audio files, play initial audio file; otherwise wait for files to load
				if ( _audioInitialPlay && !_useSpecialActionBtn && !_clickable)
					playAudio();
				else
					_audioInitialPlay = true;
			}
			
			// if has audio or dialog that plays on click, then add click interaction
			if ((_useAudio) || (_randomClickDialog) || (_clickable))
			{
				InteractionCreator.addToEntity( _npcFollower, [ InteractionCreator.CLICK, InteractionCreator.TOUCH ]);
				ToolTipCreator.addToEntity( _npcFollower );
				
				var interaction:Interaction = _npcFollower.get( Interaction );
				interaction.click.add( processClick );
				
				_useSpecialActionBtn = true;
			}
			
			// if not darkening limbs
			if (_noDarken)
			{
				var limbList:Array = [CharUtils.LEG_FRONT, CharUtils.LEG_BACK, CharUtils.FOOT_FRONT, CharUtils.FOOT_BACK, CharUtils.ARM_FRONT, CharUtils.ARM_BACK, CharUtils.HAND_FRONT, CharUtils.HAND_BACK];
				for each (var limb:String in limbList)
				{
					// get part entity and set darken percent to 0
					var partEnt:Entity = SkinUtils.getSkinPartEntity(_npcFollower, limb);
					if (partEnt != null)
					{
						var colorSet:ColorSet = partEnt.get(ColorSet);
						colorSet.darkenPercent = 0;
						colorSet.invalidate = true;
					}
				}
			}
			
			// if auto dialog delay
			if (_dialogDelay != 0)
			{
				// set delay to range of x to 2x seconds
				var delay:Number = _dialogDelay * ( 1 + Math.random());
				SceneUtil.addTimedEvent(super.group, new TimedEvent(delay, 1, doDialog));
			}
			
			// if replacing with clip, then load it
			if (_replaceWithClip)
			{
				super.loadAsset(_replaceWithClip, clipLoaded);
			}
			else
			{
				// make visible now
				_npcFollower.get(Display).visible = true;
			}
			
			// hide any parts if requested
			if (_hideParts != null)
			{
				SkinUtils.hideSkinParts(_npcFollower, _hideParts);
			}
			
			// if follower is equipped and NPC needs to be hidden, do so now
			if ( (_hideNPC) && (super.group.getEntityById(_hideNPC)) )
			{
				// move NPC off-screen
				_npcLocationY = super.group.getEntityById(_hideNPC).get(Spatial).y;
				Spatial(super.group.getEntityById(_hideNPC).get(Spatial)).y += 1000;
				
				// stop NPC from talking if doing so
				EntityUtils.removeAllWordBalloons(super.group, super.group.getEntityById(_hideNPC).get(Entity));
			}
			
			// if using special action button
			if (_useSpecialActionBtn)
			{	
				data.triggerable = true;
				if (AppConfig.mobile)
				{
					var hud:Hud = super.group.getGroupById( Hud.GROUP_ID ) as Hud;
					if( hud )
					{
						// RLH: commening this line because if prevents other abilities from triggering
						//hud.removeActionButtonHandler(_node.specialControl.onTrigger);
						hud.addActionButtonHandler( followerTrigger );
					}
				}
			}
		}
		
		/**
		 * When external clip loaded 
		 * @param clip
		 */
		private function clipLoaded(clip:MovieClip):void
		{
			if (clip == null)
				return;
			
			_clip = clip;
			
			if(_animated)
				_replacedClip = EntityUtils.createMovingTimelineEntity(super.group, clip,entity.get(Display).container,false);
			else
				_replacedClip = EntityUtils.createSpatialEntity(super.group, clip, entity.get(Display).container);
			
			_replacedClip.get(Spatial).x = _npcFollower.get(Spatial).x;
			_replacedClip.get(Spatial).y = _npcFollower.get(Spatial).y;
			
			if ((_useAudio) || (_randomClickDialog) || (_clickable))
			{
				InteractionCreator.addToEntity( _replacedClip, [ InteractionCreator.CLICK ]);
				ToolTipCreator.addToEntity( _replacedClip );
				
				var interaction:Interaction = _replacedClip.get( Interaction );
				interaction.click.add( processClick );
				_useSpecialActionBtn = true;
			}
		}
		
		public function setFollowTarget(followTarget:Entity):void
		{
			CharUtils.followEntity(_npcFollower, followTarget, new Point(_distance, 120));
		}
		override public function getLook():LookData
		{
			return _look;
		}
		
		// set look (only subset look is passed)
		override public function setLook(look:LookData):void
		{
			// apply base look to passed look (otherwise default kitten parts appear)
			look.applyBaseLook(_look, true);
			_look = look;
			
			var diffLookObj:Object = {};
			
			// create differences look object by comparing original to new look
			for (var part:String in conversionObj)
			{
				var lad:LookAspectData = look.getAspect(conversionObj[part]);
				var origPart:String = _origLook[part];
				
				// if look aspect data and part is different
				if ((lad != null) && (lad.value != origPart))
				{
					if (lad.value != "empty")
					{
						trace("Pet: save part: " + part + ": " + lad.value);
						diffLookObj[part] = lad.value;
					}
					else
					{
						trace("Pet: remove part: " + part);
					}
				}
			}
			
			SkinUtils.applyLook( _npcFollower, _look, false );
			var petID:String = "pet" + _id;
			// save to profile (only what's different)
			shellApi.profileManager.active.pets[petID] = diffLookObj;
			shellApi.profileManager.save();
			// save to database
			super.group.shellApi.setUserField(petID, diffLookObj, "", true);
			// save to lso if not mobile
			if (!AppConfig.mobile)
			{
				var pet_lso:SharedObject = ProxyUtils.getAS2LSO(petID);
				pet_lso.data.accessories = diffLookObj;
				pet_lso.flush();
			}
		}
		
		/**
		 * user clicked on popFollower, play audio
		 * @param entity
		 */
		private function processClick( entity:Entity = null):void
		{
			// if have campaign name and clicked, then track
			if (_campaignName)
			{
				// if clicked
				if (entity)
				{
					super.shellApi.adManager.track(_campaignName, AdTrackingConstants.TRACKING_CLICKED, "Follower");
				}
					// if spacebar tap or action button
				else
				{
					if (PlatformUtils.isMobileOS)
					{
						super.shellApi.adManager.track(_campaignName, SpecialAbilityControlSystem.TRACKING_ACTION_BTN_TRIGGER, "Follower");
					}
					else
					{
						super.shellApi.adManager.track(_campaignName, SpecialAbilityControlSystem.TRACKING_SPACE_BAR_TRIGGER, "Follower");
					}
				}
			}
			
			actionCall(SpecialAbilityData.CLICK_ACTIONS_ID);
			
			// play audio
			if (_useAudio)
				playAudio();
			
			if (_randomClickDialog)
			{
				var dialog:Dialog = _npcFollower.get( Dialog );
				if (dialog)
				{
					// if creature then adjust dialog bubble
					if (_variant == "creature")
					{
						if (_npcFollower.get(Spatial).scaleX < 0)
							dialog.dialogPositionPercents = new Point(1, 0.6);
						else
							dialog.dialogPositionPercents = new Point(-1, 0.6);
					}
					
					while (true)
					{
						var num:int = Math.floor(_randomClickDialog.length * Math.random());
						if (num != _lastRandom)
						{
							_lastRandom = num;
							dialog.say(_randomClickDialog[num]);
							break;
						}
					}
				}
			}
		}
		
		/**
		 * Trigger dialog after delay
		 */
		private function doDialog():void
		{
			var dialog:Dialog = _npcFollower.get( Dialog );
			if (dialog)
			{
				// if random dialog array, then play random dialog
				if (_randomDialog)
				{
					// if creature then adjust dialog bubble
					if (_variant == "creature")
					{
						if (_npcFollower.get(Spatial).scaleX < 0)
							dialog.dialogPositionPercents = new Point(1, 0.6);
						else
							dialog.dialogPositionPercents = new Point(-1, 0.6);
					}
					
					while (true)
					{
						var num:int = Math.floor(_randomDialog.length * Math.random());
						if (num != _lastRandom)
						{
							_lastRandom = num;
							dialog.say(_randomDialog[num]);
							break;
						}
					}
				}
				else
					dialog.say( _autoDialog );
				// set delay to range of x to 2x seconds
				var delay:Number = _dialogDelay * ( 1 + Math.random());
				SceneUtil.addTimedEvent(super.group, new TimedEvent(delay, 1, doDialog));
			}
		}
		
		private function followerTrigger(entity:Entity = null):void
		{
			// trigger click functions on trigger
			processClick();
		}
		
		override public function deactivate( node:SpecialAbilityNode ):void
		{
			// remove follower
			if( _npcFollower )
				super.group.removeEntity(_npcFollower);
			
			// if NPC in ad was hidden, restore NPC back to original position
			if ( (_hideNPC) && (super.group.getEntityById(_hideNPC)) )
			{
				Spatial(super.group.getEntityById(_hideNPC).get(Spatial)).y -= 1000;
			}
			
			// if item in avatar's hand, then remove
			if( _itemLookData )
				SkinUtils.removeLook( super.shellApi.player, _itemLookData, false );
			
			if (_replacedClip)
				super.group.removeEntity(_replacedClip);
			
			if(_useSpecialActionBtn && AppConfig.mobile)
			{	
				var hud:Hud = super.group.getGroupById( Hud.GROUP_ID ) as Hud;
				if( hud )
				{
					// remove trigger
					hud.removeActionButtonHandler(followerTrigger);
					
					// remove action button if there are no other current actions
					// to do: check followers for action button triggers
					var hasOtherTriggers:Boolean = false;
					var nodeList:NodeList = super.systemManager.getNodeList( SpecialAbilityNode );
					for( var saNode:SpecialAbilityNode = nodeList.head; saNode; saNode = saNode.next )
					{
						// check standard abilities
						var control:SpecialAbilityControl = saNode.specialControl;
						if (control.hasActionBtnUsers)
						{
							hasOtherTriggers = true;
							break;
						}
						// check followers
						for ( var i:int; i < control.specials.length; i++ )
						{
							var sData:SpecialAbilityData = control.specials[i];
							// if has special action button and not this, then skip out
							if (sData.specialAbility != null && (sData.specialAbility._useSpecialActionBtn) && (sData.specialAbility != this))
							{
								hasOtherTriggers = true;
								break;
							}
						}
					}
					// if not other triggers, then remove action button
					if (!hasOtherTriggers)
					{
						hud.removeActionButton();
					}
				}
			}
		}
		
		// AUDIO FUNCTIONS ///////////////////////////////////////////////////////
		
		/**
		 * load next audio file
		 */
		private function loadNextAudioFile():void
		{
			_audioFileRequest = new URLRequest("https://" + super.shellApi.siteProxy.fileHost + "/" + _audioFiles[_audioFilesLoaded]);
			_audioSounds.push(new Sound(_audioFileRequest));
			_audioSounds[_audioSounds.length - 1].addEventListener(Event.COMPLETE, audioSoundLoaded);
		}
		
		/**
		 * when the audio file has been loaded
		 * @param event
		 */
		private function audioSoundLoaded(event:Event):void
		{
			_audioFilesLoaded++;
			if ( _audioFilesLoaded < _audioFiles.length )
				loadNextAudioFile();
			else
			{
				// if user has loaded all audio files, play initial audio file; otherwies, wait for NPC to load
				if ( _audioInitialPlay )
					playAudio();
				else
					_audioInitialPlay = true;
			}
		}
		
		/**
		 * play audio file
		 */
		private function playAudio():void
		{
			// if audio files not yet loaded or audio file is being played, abort
			if ( (!_useAudio) || (_audioFilesLoaded < _audioFiles.length) || (_audioLock) )
				return;
			
			// pick a random audio file and play it
			if (_audioFiles.length == 1)
				_audioIndex = 0;
			else
				_audioIndex = randomAudioIndex();
			_audioSoundChannel = _audioSounds[_audioIndex].play();
			_audioSoundChannel.addEventListener(Event.SOUND_COMPLETE, audioSoundComplete);
			if(_pauseMusic)
				AudioUtils.getAudio(group, SceneSound.SCENE_SOUND).setVolume(0,SoundModifier.MUSIC);
			_audioLock = true;
		}
		
		/**
		 * Get random audio index 
		 * @return int
		 */
		private function randomAudioIndex():int
		{
			while (true)
			{
				// get number in range
				var index:int = Math.floor(Math.random() * _audioFiles.length);
				// if not same as last audio index, then break
				if (index != _audioIndex)
					break;
			}
			return index;
		}
		
		/**
		 * when the audio file has finished playing 
		 * @param event
		 */
		private function audioSoundComplete(event:Event):void
		{
			if(_pauseMusic)
				AudioUtils.getAudio(group, SceneSound.SCENE_SOUND).setVolume(shellApi.profileManager.active.musicVolume,SoundModifier.MUSIC);
			_audioLock = false;
		}
		
		public var _gender:String = SkinUtils.GENDER_MALE;
		public var _skinColor:uint = 0xFFCC66;
		public var _hairColor:uint = 0x0; // black
		public var _eyeState:String = "squint";
		public var _eyesFrame:String = "eyes";
		public var _mouthFrame:String = "1";
		public var _marksFrame:String = "empty";
		public var _facialFrame:String = "empty";
		public var _hairFrame:String = "empty";
		public var _shirtFrame:String = "empty";
		public var _pantsFrame:String = "empty";
		public var _packFrame:String = "empty";
		public var _itemFrame:String = "empty";
		public var _overshirtFrame:String = "empty";
		public var _overpantsFrame:String = "empty";
		public var _headFrame:String = "headSkin";
		public var _bodyFrame:String = "bodySkin";
		
		public var _tailFrame:String = "empty";
		public var _paw1Frame:String = "empty";
		public var _paw2Frame:String = "empty";
		public var _paw3Frame:String = "empty";
		public var _paw4Frame:String = "empty";
		public var _calf1Frame:String = "empty";
		public var _calf2Frame:String = "empty";
		public var _calf3Frame:String = "empty";
		public var _calf4Frame:String = "empty";
		public var _thigh1Frame:String = "empty";
		public var _thigh2Frame:String = "empty";
		public var _thigh3Frame:String = "empty";
		public var _thigh4Frame:String = "empty";
		public var _overbodyFrame:String = "empty";
		public var _hatFrame:String = "empty";
		
		public var _avatarItemFrame:String;
		public var _campaignName:String;
		public var _noDarken:Boolean = false;
		public var _isTwin:Boolean = false;
		public var _variant:String = "";
		public var _scaleSize:Number = 0;
		public var _hideNPC:String; // entity ID
		public var _hideParts:Array;
		public var _autoDialog:String;
		public var _randomDialog:Array;
		public var _randomClickDialog:Array;
		public var _dialogDelay:Number = 0;
		public var _lineThickness:Number = 0;
		public var _replaceWithClip:String;
		public var _animated:Boolean = false;
		public var _flippablePart:Boolean;
		public var _clickable:Boolean = false;
		public var _distance:Number = 120; // default distance from avatar
		
		private var _npcFollower:Entity;
		private var _look:LookData;
		private var _followerLoaded:Boolean = false;
		private var _npcLocationY:Number;
		private var _itemLookData:LookData;
		private var _replacedClip:Entity;
		private var _clip:MovieClip;
		private var _lastRandom:int = -1;
		private var _node:SpecialAbilityNode;
		private var _isPet:Boolean = false;
		
		public var _audioFile1:String;
		public var _pauseMusic:Boolean;
		// because this class is dynamic, we don't need to declare all the audio files
		//public var _audioFile2:String;
		//public var _audioFile3:String;
		//public var _audioFile4:String;
		
		private var _useAudio:Boolean = false;
		private var _audioFiles:Array;
		private var _audioFilesLoaded:int;
		private var _audioSounds:Array;
		private var _audioFileRequest:URLRequest;
		private var _audioSoundChannel:SoundChannel;
		private var _audioLock:Boolean;
		private var _audioInitialPlay:Boolean;
		private var _audioIndex:int = -1;
		private var _playingAnimation:Boolean = false;
		private var _origLook:Object;
		private var overrideOldEntity:Boolean = false;
		// conversion object between pet pop follower variables and pet skin IDs
		private var conversionObj:Object = {skinColor:SkinUtils.SKIN_COLOR, facialFrame:SkinUtils.FACIAL, eyesFrame:SkinUtils.EYES, hatFrame:SkinUtils.HAT, overbodyFrame:SkinUtils.OVERBODY};
	}
}
