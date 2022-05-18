package game.scene.template
{
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.utils.Dictionary;
	
	import ash.core.Entity;
	import ash.core.NodeList;
	
	import engine.components.Audio;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Motion;
	import engine.components.MotionBounds;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	import engine.group.DisplayGroup;
	import engine.group.Group;
	import engine.group.Scene;
	import engine.util.Command;
	
	import game.components.Viewport;
	import game.components.animation.FSMControl;
	import game.components.animation.FSMMaster;
	import game.components.audio.HitAudio;
	import game.components.entity.character.BitmapCharacter;
	import game.components.entity.character.Character;
	import game.components.entity.character.CharacterMotionControl;
	import game.components.entity.character.CharacterMovement;
	import game.components.entity.character.CharacterProximity;
	import game.components.entity.character.ColorSet;
	import game.components.entity.character.Creature;
	import game.components.entity.character.JumpTargetIndicator;
	import game.components.entity.character.Player;
	import game.components.entity.character.Profile;
	import game.components.entity.collider.BitmapCollider;
	import game.components.entity.collider.BounceWireCollider;
	import game.components.entity.collider.ClimbCollider;
	import game.components.entity.collider.EmitterCollider;
	import game.components.entity.collider.HazardCollider;
	import game.components.entity.collider.PlatformCollider;
	import game.components.entity.collider.SceneCollider;
	import game.components.entity.collider.WallCollider;
	import game.components.entity.collider.WaterCollider;
	import game.components.entity.collider.ZoneCollider;
	import game.components.hit.CurrentHit;
	import game.components.motion.MotionControl;
	import game.components.motion.MotionTarget;
	import game.components.render.Line;
	import game.components.render.PlatformDepthCollider;
	import game.creators.animation.FSMStateCreator;
	import game.creators.entity.BitmapTimelineCreator;
	import game.creators.entity.character.BitmapCharacterCreator;
	import game.creators.entity.character.CharacterCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.animation.AnimationLibrary;
	import game.data.animation.AnimationSequence;
	import game.data.animation.entity.character.Climb;
	import game.data.animation.entity.character.ClimbDown;
	import game.data.animation.entity.character.DuckDown;
	import game.data.animation.entity.character.DuckSpin;
	import game.data.animation.entity.character.DuckSpinUp;
	import game.data.animation.entity.character.DuckUp;
	import game.data.animation.entity.character.Fall;
	import game.data.animation.entity.character.Hurt;
	import game.data.animation.entity.character.Jump;
	import game.data.animation.entity.character.JumpSpin;
	import game.data.animation.entity.character.Land;
	import game.data.animation.entity.character.LandSpin;
	import game.data.animation.entity.character.Run;
	import game.data.animation.entity.character.Skid;
	import game.data.animation.entity.character.Spin;
	import game.data.animation.entity.character.Stand;
	import game.data.animation.entity.character.Swim;
	import game.data.animation.entity.character.SwimLand;
	import game.data.animation.entity.character.SwimLandSpin;
	import game.data.animation.entity.character.SwimTread;
	import game.data.animation.entity.character.Walk;
	import game.data.character.CharacterData;
	import game.data.character.CharacterSceneData;
	import game.data.character.LookConverter;
	import game.data.character.LookData;
	import game.data.character.NpcParser;
	import game.data.game.GameEvent;
	import game.managers.ProfileManager;
	import game.nodes.entity.character.CharacterUpdateNode;
	import game.nodes.entity.character.clipChar.MovieclipStateNode;
	import game.systems.SystemPriorities;
	import game.systems.entity.AnimationLoaderSystem;
	import game.systems.entity.character.CharacterJumpAssistSystem;
	import game.systems.entity.character.CharacterMotionControlSystem;
	import game.systems.entity.character.CharacterMovementSystem;
	import game.systems.entity.character.CharacterUpdateSystem;
	import game.systems.entity.character.CharacterWanderSystem;
	import game.systems.entity.character.clipChar.MovieclipState;
	import game.systems.entity.character.states.CharacterState;
	import game.systems.entity.character.states.ClimbState;
	import game.systems.entity.character.states.DiveState;
	import game.systems.entity.character.states.DuckState;
	import game.systems.entity.character.states.FallState;
	import game.systems.entity.character.states.HurtState;
	import game.systems.entity.character.states.LandState;
	import game.systems.entity.character.states.PushState;
	import game.systems.entity.character.states.RunState;
	import game.systems.entity.character.states.SwimState;
	import game.systems.entity.character.states.WalkState;
	import game.systems.entity.character.states.movieClip.MCDiveState;
	import game.systems.entity.character.states.movieClip.MCDuckState;
	import game.systems.entity.character.states.movieClip.MCFallState;
	import game.systems.entity.character.states.movieClip.MCHurtState;
	import game.systems.entity.character.states.movieClip.MCJumpState;
	import game.systems.entity.character.states.movieClip.MCLandState;
	import game.systems.entity.character.states.movieClip.MCRunState;
	import game.systems.entity.character.states.movieClip.MCStandState;
	import game.systems.entity.character.states.movieClip.MCStateNode;
	import game.systems.entity.character.states.movieClip.MCSwimState;
	import game.systems.entity.character.states.movieClip.MCWalkState;
	import game.systems.entity.character.states.touch.DiveState;
	import game.systems.entity.character.states.touch.JumpState;
	import game.systems.entity.character.states.touch.SkidState;
	import game.systems.entity.character.states.touch.StandState;
	import game.systems.entity.character.states.touch.SwimState;
	import game.ui.hud.Hud;
	import game.util.CharUtils;
	import game.util.DataUtils;
	import game.util.PlatformUtils;
	import game.util.SkinUtils;
	import game.util.TribeUtils;
	
	import org.osflash.signals.Signal;
	
	public class CharacterGroup extends Group
	{
		public function CharacterGroup()
		{
			super();
			this.id = GROUP_ID;
		}
		
		override public function destroy():void
		{		
			_charsLoadingById = null;
			_characterContainer = null;
			if( _charactersLoaded != null )
			{
				_charactersLoaded.removeAll();
				_charactersLoaded = null;
			}
			super.destroy();
		}
		
		/**
		 * Preload animations, creates animations at start of scene so there aren't delays mid-scene during animation load   
		 * @param anims
		 */
		public function preloadAnimations( anims:Vector.<Class>, group:Group = null, type:String = AnimationLibrary.CHARACTER ):void
		{
			if( !group ) { group = _targetGroup; }
			if( group )
			{
				var animLaoderSys:AnimationLoaderSystem = group.getSystem( AnimationLoaderSystem ) as AnimationLoaderSystem;
				if( !animLaoderSys )	{ group.addSystem( new AnimationLoaderSystem() ); }
				
				for (var i:int = 0; i < anims.length; i++) 
				{
					animLaoderSys.animationLibrary.add( anims[i], type );
				}	
			}
			else
			{
				trace( "Error :: CharacterGroup : A group muct be specified." );
			}
		}
		
		/**
		 * Setup characters for Scene.
		 * @param scene - Scene characters will be added to
		 * @param characterContainer - DisplayObjectConatiner that character displays will be added to
		 * @param npcXML - XML defining npcs, generally the npcs.xml associated with scenes
		 * @param charsLoadedCallback - called when all characters have finished loading
		 * @param addPlayer - flag to determine whether player is created
		 * @param addNpcs - flag to determine whether npcs are created
		 */
		public function setupScene(scene:Scene, characterContainer:DisplayObjectContainer, npcXML:XML = null, charsLoadedCallback:Function = null, addPlayer:Boolean = true, addNpcs:Boolean = true):void
		{
			_targetGroup = scene;
			
			_characterContainer = characterContainer;
			// add it as a child group to give it access to systemManager.
			scene.addChildGroup(this);
			
			// instantiate private classes, add base systems necessary for loading, display and animation of characters.
			setup( scene );
			
			if(scene.sceneData)
			{
				(scene.getSystem(CharacterUpdateSystem) as CharacterUpdateSystem).sceneBounds = scene.sceneData.bounds;
			}
			
			if(charsLoadedCallback != null)
			{
				_charactersLoaded.addOnce(charsLoadedCallback);
			}
			
			// add systems specific to moving the character around based on input.
			scene.addSystem(new CharacterMotionControlSystem());
			scene.addSystem(new CharacterMovementSystem());
			//if(PlatformUtils.isMobileOS)
			//{
			scene.addSystem(new CharacterJumpAssistSystem());
			//}
			
			if ( addNpcs && npcXML != null )		
			{ 
				createNpcsFromXML( npcXML );
				super.systemManager.addSystem(new CharacterWanderSystem(), SystemPriorities.moveComplete);
			}
			
			if ( addPlayer ) 	
			{ 
				createPlayer();
				
				if(scene is PlatformerGameScene)// && PlatformUtils.isMobileOS)
				{
					createJumpIndicator(PlatformerGameScene(scene).uiLayer);
				}
			}
		}
		
		/**
		 *  Setup characters for Group.
		 * @param group - Group characters will be added to
		 * @param characterContainer - DisplayObjectConatiner that character displays will be added to
		 * @param npcXML - XML defining npcs, generally the npcs.xml associated with scenes
		 * @param charsLoadedCallback - called when all characters have finished loading
		 * @param addPlayer - flag to determine whether player is created
		 * @param addPlayer
		 */
		public function setupGroup(group:DisplayGroup, characterContainer:DisplayObjectContainer = null, npcXML:XML = null, charsLoadedCallback:Function = null, addPlayer:Boolean = false):void
		{
			_targetGroup = group;
			
			_characterContainer = characterContainer;
			// add it as a child group to give it access to systemManager.
			group.addChildGroup(this);
			
			// instantiate private classes, add base systems necessary for loading, display and animation of characters.
			setup( group );
			
			if(charsLoadedCallback != null)
			{
				_charactersLoaded.addOnce(charsLoadedCallback);
			}
			
			if( npcXML != null ){ createNpcsFromXML( npcXML ); }
			if ( addPlayer ) 	{ createPlayer() };
		}
		
		private function setup( group:Group ):void
		{			
			_charsLoadingById = new Vector.<String>();
			_charactersLoaded = new Signal();
			_characterCreator = new CharacterCreator();
			_characterCreator.addSystems( group );
			_lookConverter = new LookConverter();
			_bitmapCharacterCreator = new BitmapCharacterCreator();
			_stateCreator = new FSMStateCreator();
			preloadAnimations( _defaultAnims );	// NOTE ::call this after adding necessary systems
		}
		
		//////////////////////////////////////////////////////////
		///////////////////////// PLAYER /////////////////////////
		//////////////////////////////////////////////////////////
		
		/**
		 * Creates player entity.
		 * @param charData : data class use to define a character, tied to event
		 * @param loadedCallback : called when character has finished loading, including all parts, called with params [ Entity ]
		 * @return 
		 */
		public function createPlayer( charData:CharacterData = null, loadedCallback:Function = null ):Entity
		{
			if ( charData == null )
			{
				charData = createPlayerData();
			}
			
			// add character specific systems
			//_targetGroup.addSystem(new CharacterDepthSystem());
			
			var charEntity:Entity = _characterCreator.createFromCharData(_targetGroup, charData, _characterContainer);
			addLoadCheck( charEntity, loadedCallback );
			
			var profile:Profile = new Profile( super.shellApi.profileManager, super.shellApi.profileManager.active );
			
			charEntity.add( profile );
			
			super.shellApi.player = charEntity;
			profile.save();
			
			return charEntity;
		}
		
		/**
		 * Create a CharacterData from the current player
		 */
		public function createPlayerData():CharacterData
		{
			var characterData:CharacterData = new CharacterData();
			
			characterData.id			= CharacterCreator.TYPE_PLAYER;
			characterData.type			= CharacterCreator.TYPE_PLAYER;
			characterData.variant		= CharacterCreator.VARIANT_HUMAN;
			characterData.dynamicParts 	= true;
			
			// apply look
			if( shellApi.profileManager.active.look )
			{
				var look:LookData = _lookConverter.lookDataFromPlayerLook( shellApi.profileManager.active.look );
				characterData.look = look;
			}
			else
			{
				characterData.look = new LookData();
			}
			var profileManager:ProfileManager = shellApi.getManager(ProfileManager) as ProfileManager;
			
			// TODO :: Would prefer if tribe data was part of standard profile data and not store in a userfield. -bard
			// check for/apply tribe
			if(profileManager.active.tribeData == null) 
			{
				var tribeValue:* = shellApi.getUserField( TribeUtils.TRIBE_FIELD );
				trace("Value from userfield for TRIBE: " + tribeValue);
				if( DataUtils.isValidStringOrNumber(tribeValue) )
				{
					profileManager.active.tribeData = TribeUtils.getTribeDataByIndex( tribeValue as int ); 
				}
			}
			
			characterData.position.x 	= profileManager.active.lastX;
			characterData.position.y 	= profileManager.active.lastY;
			characterData.direction 	= profileManager.active.lastDirection;
			characterData.event 		= GameEvent.DEFAULT;	// set the event to default
			
			// Pull scale from sceneData.  
			// NOTE :: Not really how I want to do this, would prefer all player infor be grouped with other npcs data in npcs.xml. - bard
			if( _targetGroup != null )
			{
				if( _targetGroup is Scene )
				{
					var scale:Number = Scene(_targetGroup).sceneData.playerScale;
					if( !isNaN(scale) )
					{
						characterData.scale = scale;
					}	
				}
			}
			
			return characterData;
		}
		
		//////////////////////////////////////////////////////////
		/////////////////////////// NPC //////////////////////////
		//////////////////////////////////////////////////////////
		
		/**
		 * Creates npc characters from given list of CharacterData.
		 * @param npcs
		 * @param charsLoadedCallback : called when all characters have finished loading, including their parts
		 */
		public function createNpcsFromData( npcs:Vector.<CharacterData>, charsLoadedCallback:Function = null ):void
		{
			if ( npcs.length > 0 )		
			{ 
				if(charsLoadedCallback != null) { _charactersLoaded.addOnce(charsLoadedCallback); }
				
				for (var i:int = 0; i < npcs.length; i++) 
				{
					createNpcFromData( npcs[i] );
				}
			}
			else
			{
				if(charsLoadedCallback != null) { charsLoadedCallback(); }
			}
		}
		
		/**
		 * Creates non-player character with player look.
		 * @param loadedCallback : called when all characters have finished loading, including their parts, called with params [ Entity ]
		 * @param animSequence
		 * @param startPosition
		 * @param type
		 * @return 
		 */
		public function createNpcPlayer( loadedCallback:Function = null, animSequence:AnimationSequence = null, startPosition:Point = null, type:String = CharacterCreator.TYPE_NPC ):Entity
		{
			var characterData:CharacterData = new CharacterData();
			
			characterData.id			= CharacterCreator.TYPE_PLAYER;
			characterData.type			= type;
			characterData.variant		= CharacterCreator.VARIANT_HUMAN;
			characterData.dynamicParts 	= false;
			characterData.animSequence 	= animSequence;
			
			// apply look
			if( shellApi.profileManager.active.look )
			{
				var look:LookData = _lookConverter.lookDataFromPlayerLook( shellApi.profileManager.active.look );
				characterData.look = look;
			}
			else
			{
				characterData.look = new LookData();
			}
			
			// check for/apply tribe
			if( shellApi.profileManager.active.tribeData == null )
			{
				var tribeValue:* = shellApi.getUserField( TribeUtils.TRIBE_FIELD )
				if( DataUtils.isValidStringOrNumber(tribeValue) )
				{
					shellApi.profileManager.active.tribeData = TribeUtils.getTribeDataByIndex( tribeValue as int ); 
				}
			}
			
			if(startPosition == null)
			{
				characterData.position.x 	= super.shellApi.profileManager.active.lastX;
				characterData.position.y 	= super.shellApi.profileManager.active.lastY;
			}
			else
			{
				characterData.position.x 	= startPosition.x;
				characterData.position.y 	= startPosition.y;
			}
			
			characterData.direction 	= super.shellApi.profileManager.active.lastDirection;
			characterData.event 		= GameEvent.DEFAULT;	// set the event to default
			
			if( characterData.type == CharacterCreator.TYPE_NPC )
			{
				return createNpcFromData( characterData, loadedCallback );
			}
			else if( characterData.type == CharacterCreator.TYPE_DUMMY || characterData.type == CharacterCreator.TYPE_PORTRAIT )
			{
				return createDummyFromData( characterData, _characterContainer, null, loadedCallback );
			}
			else
			{
				trace( this,"createNpcPlayer : invalid type: " + characterData.type );
				return null;
			}
		}
		
		
		/**
		 * Creates NPCs defined within xml, usually used in conjunction with initial group setup.
		 * @param npcsXml
		 */
		private function createNpcsFromXML(npcsXml:XML):void
		{
			if (npcsXml != null)
			{
				if( !_npcParser ) { _npcParser = new NpcParser(); }
				var allCharSceneData:Dictionary = _npcParser.parse(npcsXml);	// returns Dictionary of (npc id as key)CharacterSceneData
				
				var charEntity:Entity;
				for each (var charSceneData:CharacterSceneData in allCharSceneData)	
				{
					charSceneData.addToolTip = this.addToolTips;
					
					// determine if character is clip or rig driven
					// TODO :: want to detemerine if char is bitmap sooner.
					var currentData:CharacterData;
					var defaultCharData:CharacterData = charSceneData.getCharData("default");	// get default character data
					if ( (defaultCharData != null) && (defaultCharData.bitmap != null) )  		// if data found and bitmap character
					{
						charEntity = _bitmapCharacterCreator.createFromCharSceneData(_targetGroup, charSceneData, _characterContainer);
						addLoadCheck( charEntity );
					}
					else
					{
						charEntity = _characterCreator.createFromCharSceneData(_targetGroup, charSceneData, _characterContainer);
						addLoadCheck( charEntity );
					}
					
					// used by ads, if NPCs have proximity
					if ((defaultCharData != null) && (defaultCharData.proximity > -1))
					{
						var charProximity:CharacterProximity = new CharacterProximity();
						charProximity.proximity = defaultCharData.proximity;
						charEntity.add( charProximity );
					}
				}
			}
		}
		
		/**
		 * Creates npc entity.
		 * @param id
		 * @param look
		 * @param x
		 * @param y
		 * @param direction
		 * @param variant
		 * @param animSequence
		 * @param loadedCallback : Function called when character has finished loading, including all parts, called with params [ Entity ]
		 * @return 
		 */
		public function createNpc( id:String, look:LookData, x:int = 0, y:int = 0, direction:String = "right", variant:String = "", animSequence:AnimationSequence = null, loadedCallback:Function = null):Entity
		{
			var charData:CharacterData = new CharacterData();
			
			charData.id				= id;
			charData.type			= CharacterCreator.TYPE_NPC;
			charData.variant		= ( variant == "" ) ?  CharacterCreator.VARIANT_HUMAN : variant;
			
			charData.look 			= look;
			charData.position.x 	= x;
			charData.position.y 	= y;
			charData.direction 		= direction;
			charData.animSequence 	= animSequence;
			charData.event 			= GameEvent.DEFAULT;	// set the event to default
			
			// if follower then make not costumizable
			if (id.indexOf("popFollower") == 0)
			{
				charData.costumizable = false;
			}
			
			return createNpcFromData( charData, loadedCallback ) ;
		}
		
		/**
		 * Creates npc entity.
		 * @param charData : data class use to define a character, tied to event
		 * @param loadedCallback : Function called when character has finished loading, called with params [ Entity ]
		 * @return 
		 */
		public function createNpcFromData( charData:CharacterData, loadedCallback:Function = null ):Entity
		{
			charData.addToolTip = this.addToolTips;
			var charEntity:Entity = _characterCreator.createFromCharData(_targetGroup, charData, _characterContainer);
			addLoadCheck( charEntity, loadedCallback );
			
			return charEntity;
		}
		
		/**
		 * Creates a dummy entity, does not get add to loading total.
		 * @param id
		 * @param look
		 * @param direction
		 * @param variant
		 * @param container
		 * @param group
		 * @param loadedCallback : Function called when character has finished loading, called with params [ Entity ]
		 * @return 
		 */
		public function createDummy( id:String, look:LookData, direction:String = "right", variant:String = "", container:DisplayObjectContainer = null, parentGroup:Group = null, loadedCallback:Function = null, dynamicParts:Boolean = false, scale:Number = NaN, type:String = CharacterCreator.TYPE_DUMMY, position:Point = null):Entity
		{
			var charData:CharacterData = new CharacterData();
			
			charData.id				= id;
			charData.type			= type;
			charData.variant		= ( variant == "" ) ?  CharacterCreator.VARIANT_HUMAN : variant;
			charData.dynamicParts	= dynamicParts;
			charData.scale			= scale;
			charData.look 			= look;
			charData.direction 		= direction;
			charData.event 			= GameEvent.DEFAULT;	// set the event to default
			if( position != null)	{ charData.position	= position; }
			
			return createDummyFromData( charData, container, parentGroup, loadedCallback );
		}
		
		/**
		 * Create a 'dummy' type character.
		 * Dummy type characters can play animations but are not given motion, interactions, or FSMs
		 * @param charData - CharacterData defining character
		 * @param container - DisplayObjectContainer character's display will be added to.
		 * @param parentGroup - Group character will be added to 
		 * @param loadedCallback - Function called when character entity has finished loading, called with params [ Entity ]
		 * @return 
		 */
		public function createDummyFromData( charData:CharacterData, container:DisplayObjectContainer = null, parentGroup:Group = null, loadedCallback:Function = null):Entity
		{
			container = ( container != null ) ? container : _characterContainer;
			parentGroup = ( parentGroup != null ) ? parentGroup : _targetGroup;
			
			if(_characterCreator == null)
			{
				_characterCreator = new CharacterCreator();
			}
			
			var charEntity:Entity = _characterCreator.createFromCharData( parentGroup, charData, container );
			
			var character:Character = charEntity.get( Character );
			if( character )
			{
				if( loadedCallback != null )	{ character.loadComplete.addOnce( Command.create( loadedCallback, charEntity ) ); }
			}
			
			return charEntity;
		}
		
		public function configureCostumizerMannequin(entity:Entity):void
		{
			var squareWidth:int = 250;
			var squareHeight:int = 300;
			
			var square:MovieClip = entity.get(Display).displayObject as MovieClip;
			square.graphics.beginFill(0xFFFFFF,0);
			// TODO :: should be in proportion to scale
			square.graphics.drawRect(-squareWidth / 2, -squareHeight / 1.7, squareWidth, squareHeight);
			square.graphics.endFill();
			
			ToolTipCreator.addToEntity(entity);
			
			// add interaction for npc
			var interaction:Interaction = InteractionCreator.addToEntity(entity, [InteractionCreator.CLICK]);
			interaction.click.add(this.openCostumizer);
		}
		
		/**
		 * Opens Costumizer
		 * TODO :: Would prefer this not be in CharacterGroup, maybe can find another home. - bard 
		 * @param entity
		 * 
		 */
		private function openCostumizer(entity:Entity):void
		{
			var lookData:LookData 	= SkinUtils.getLook(entity);
			lookData.variant 		= entity.get(Character).variant;
			
			var hud:Hud = this.getGroupById(Hud.GROUP_ID) as Hud;
			hud.openHud();
			hud.openCostumizer(lookData);
		}
		
		///////////////////////////////////////////////////////////////////////////////
		/////////////////////////// ADDITIONAL FUNCTIONALITY //////////////////////////
		///////////////////////////////////////////////////////////////////////////////
		
		/**
		 * Add character state control to character.
		 */
		public function addFSM( entity:Entity, isActive:Boolean = true, stateClasses:Vector.<Class> = null, startState:String = "", includeAudio:Boolean = false):FSMControl
		{
			// make sure components necessary for CharacterStateNode have been added to the entity
			if(!entity.get(MotionControl)) 			{ entity.add(new MotionControl()); }
			if(!entity.get(MotionTarget)) 			{ entity.add(new MotionTarget()); }
			if(!entity.get(CharacterMovement)) 		{ entity.add(new CharacterMovement()); }
			if(!entity.get(EmitterCollider))		{ entity.add(new EmitterCollider()); }
			
			var charMotionControl:CharacterMotionControl = entity.get(CharacterMotionControl);
			if (!charMotionControl)
			{
				charMotionControl = new CharacterMotionControl();
				entity.add(charMotionControl);
			}
			// allow for auto target jump if on touch screen device
			if(PlatformUtils.isMobileOS)
			{
				charMotionControl.allowAutoTarget = false;
			}
			
			// add Viewport, CharacterStateControl & CharacterMotionControl listen for viewport change
			var viewport:Viewport = entity.get( Viewport )
			if ( !viewport )
			{
				viewport = new Viewport();
				entity.add( viewport );
				viewport.changed.add( charMotionControl.viewportChanged );
			}
			
			// add/set Motion
			var motion:Motion = entity.get( Motion )
			if ( !motion )
			{
				motion = new Motion();
				entity.add( motion );
			}
			motion.friction 	= new Point(0, 0);
			motion.maxVelocity 	= new Point(charMotionControl.maxVelocityX, charMotionControl.maxVelocityY);
			motion.minVelocity 	= new Point(0, 0);
			
			// add collisions, needed for CharacterStateNode
			addColliders( entity );
			
			// add FSMControl and states
			var fsmControl:FSMControl = entity.get( FSMControl );
			if ( !fsmControl )
			{
				fsmControl = new FSMControl(super.shellApi);
				entity.add( fsmControl );
				entity.add( new FSMMaster() );
				if( !stateClasses )	// is states not defined, apply defaults
				{
					if(Character(entity.get(Character)).variant == CharacterCreator.VARIANT_MOVIECLIP)
					{
						stateClasses = movieClipStateSet;
					}
					else
					{
						if( entity.has(Creature) )
						{
							// if pet
							if (entity.get(Creature).variant == Creature.PET_BABYQUAD)
							{
								stateClasses = petStateSet;
							}
							else
							{
								stateClasses = creatureStateSet;
							}
						}
						else
						{
							if( PlatformUtils.isMobileOS )
							{
								stateClasses = charTouchStateSet; 	
							}
							else
							{
								stateClasses = charStateSet;	
							}
						}
					}
				}
				
				if(Character(entity.get(Character)).variant == CharacterCreator.VARIANT_MOVIECLIP)
				{
					_stateCreator.createStateSet( stateClasses, entity, MCStateNode );
				}
				else
				{
					_stateCreator.createCharacterStateSet( stateClasses, entity );
				}
				
				// if startState not defined, stand state is used
				startState = ( DataUtils.validString( startState ) ) ? startState : CharacterState.STAND;
				fsmControl.setState( startState );	
				
				entity.add( fsmControl );
			}
			
			// set viewPort (this applies viewport to necessary classes )
			viewport.setDimensions( super.shellApi.viewportWidth, super.shellApi.viewportHeight );
			
			// turn on state control on
			if( isActive )	
			{ 
				CharUtils.stateDrivenOn(entity); 
			}
			else
			{
				CharUtils.stateDrivenOff(entity); 
			}
			
			if( includeAudio ) { addAudio( entity ); }
			
			return fsmControl;
		}
		
		public function addTimelineFSM(entity:Entity, isActive:Boolean, stateClasses:Vector.<Class>, startState:String = "", colliders:Boolean = true, includeAudio:Boolean = false):FSMControl
		{
			// make sure components necessary for CharacterStateNode have been added to the entity
			if(!entity.get(MotionControl)) 			{ entity.add(new MotionControl()); }
			if(!entity.get(MotionTarget)) 			{ entity.add(new MotionTarget()); }
			
			// add/set Motion
			var motion:Motion = entity.get( Motion )
			if ( !motion )
			{
				motion = new Motion();
				entity.add( motion );
			}
			motion.friction = new Point(0, 0);
			
			// add collisions
			if(colliders)
				addColliders( entity );
			
			var fsmControl:FSMControl = entity.get( FSMControl );
			if ( !fsmControl )
			{
				fsmControl = new FSMControl(super.shellApi);
				entity.add(fsmControl);
				entity.add(new FSMMaster());
				
				_stateCreator.createStateSet(stateClasses, entity, MovieclipStateNode);
				startState = (DataUtils.validString(startState)) ? startState : MovieclipState.STAND;
				fsmControl.setState(startState);
				entity.add(fsmControl);
			}
			
			// turn on state control on
			if( isActive )	
			{ 
				CharUtils.stateDrivenOn(entity); 
			}
			else
			{
				CharUtils.stateDrivenOff(entity); 
			}
			
			if( includeAudio ) { addAudio( entity ); }
			
			return fsmControl;
		}
		
		public function removeFSM( entity:Entity):void
		{
			//entity.remove(MotionControl);
			//entity.remove(MotionTarget);
			entity.remove(CharacterMotionControl);
			entity.remove( Viewport );
			removeCollliders( entity );
			entity.remove( FSMControl );	// TODO :: Could probably do better clean up of states
		}
		
		/**
		 * Add audio components to character
		 */
		public function addAudio(entity:Entity):void
		{
			if(!entity.get(Audio)) 		{ entity.add(new Audio()); }
			if(!entity.get(HitAudio)) 	{ entity.add(new HitAudio()); }
			if(!entity.get(CurrentHit)) { entity.add(new CurrentHit()); }
		}
		
		/**
		 * Add colliders and motion bounds to character, where bounds are equal to the scene bounds.
		 */
		public function addColliders(entity:Entity, colliders:Vector.<Class> = null ):void
		{
			// if colliders not defined, use defaults
			if( colliders == null )
			{
				colliders = new <Class>[ SceneCollider, PlatformCollider, ClimbCollider, BitmapCollider, 
					ZoneCollider, CurrentHit, HazardCollider, WaterCollider, BounceWireCollider, WallCollider, PlatformDepthCollider ];
			}
			
			var colliderClass:Class;
			var collider:*;
			var i:int;
			for ( i = 0; i < colliders.length; i++ )
			{
				colliderClass = colliders[i];
				collider = entity.get( colliderClass );
				if ( !collider )
				{
					collider = new colliderClass();
					entity.add( collider );
					if( colliderClass == WaterCollider )	// WaterCollider requires some specific vars for characters
					{
						WaterCollider(collider).density = CharUtils.DENSITY;	// standard density of a character	
						WaterCollider(collider).surfaceResistance = CharUtils.SURFACE_RESISTANCE;
						WaterCollider(collider).floatAtSurface = true;
						
						var character:Character = entity.get(Character);
						if( character )
						{
							var variantType:String = (entity.get(Character) as Character).variant;
							// TODO :: surfaceOffset should be defined in xml and pulled from entity.  Could be percentage of original edge...
							if( variantType == CharacterCreator.VARIANT_HUMAN )
							{
								WaterCollider(collider).surfaceOffset = -10;
							}
							else if ( variantType == CharacterCreator.VARIANT_CREATURE )
							{
								WaterCollider(collider).surfaceOffset = 16;
							}
							else if ( variantType == CharacterCreator.VARIANT_PET_BABYQUAD )
							{
								// surfaceOffsest is only applied when the player is not swimming or diving
								// for example: when the player is standing in the waterfall2 scene on viking island but the pet is still in the water
								// if you adjust the surfaceOffset, you may want to adjust PET_OFFSET in SwimState
								WaterCollider(collider).surfaceOffset = 38;
								WaterCollider(collider).dampener = 0.75; // normally 1
								WaterCollider(collider).isPet = true;
							}
							else if ( variantType == CharacterCreator.VARIANT_APE )
							{
								WaterCollider(collider).surfaceOffset = 6;	// TODO :: May need adjustment, need ape animation to be fixed to gauge. - Bard
							}
						}
					}
				}
			}
			
			// set motion bounds, only applied if group is a Scene
			if ( _targetGroup is Scene )
			{
				var motionBounds:MotionBounds = entity.get( MotionBounds )
				if ( !motionBounds )
				{
					motionBounds = new MotionBounds();
					entity.add( motionBounds );
				}
				motionBounds.box = Scene(_targetGroup).sceneData.bounds;
			}
		}
		
		public function removeCollliders(entity:Entity, colliders:Vector.<Class> = null):void
		{
			if( colliders == null )
			{
				colliders = new <Class>[ SceneCollider, PlatformCollider, ClimbCollider, BitmapCollider, 
					ZoneCollider, CurrentHit, HazardCollider, WaterCollider, BounceWireCollider, MotionBounds ];
			}
			
			var colliderClass:Class;
			var collider:*;
			var i:int;
			for ( i = 0; i < colliders.length; i++ )
			{
				colliderClass = colliders[i];
				entity.remove( colliderClass );
			}
		}
		
		//////////////////////////////////////////////////////////
		/////////////////////////// HELPERS //////////////////////
		//////////////////////////////////////////////////////////
		
		/*
		public function addToolTip(entity:Entity, characterData:CharacterData):void
		{
		var labelData:LabelData = characterData.label;
		
		if(labelData == null)
		{
		labelData = new LabelData();
		labelData.type = ToolTipType.CLICK;
		}
		
		ToolTipCreator.addToEntity(entity, labelData.type, labelData.text, labelData.offset, true, 1);
		}
		
		/**
		* Searches through all characters in scene, returning the ones that are within the current view.
		* If npcOnly is true the player will not be return with the list.
		*/
		public function getCharactersInView( npcOnly:Boolean = true ):Vector.<Entity>
		{
			var charsInView:Vector.<Entity>;
			
			var nodeList:NodeList = super.systemManager.getNodeList( CharacterUpdateNode );
			for( var node : CharacterUpdateNode = nodeList.head; node; node = node.next )
			{
				if( npcOnly && node.entity.get(Player) )
				{
					continue;
				}
				// filter out pets
				if(node.entity.get(Character).currentCharData != null) {
					if (node.entity.get(Character).currentCharData.variant == CharacterData.VARIANT_PET_BABYQUAD) {
						continue;
					}
				}
				// check if character is within viewport
				// TODO :: may need to account for camera offset, need to test this
				if( super.shellApi.camera.viewport.contains( node.spatial.x, node.spatial.y ) )	
				{
					if( !charsInView )
					{
						charsInView = new Vector.<Entity>();
					}
					
					charsInView.push( node.entity )
				}
			}
			
			return charsInView;
		}
		
		
		/**
		 * Get NPCs in scene 
		 * @param type: ALL, NPCS, AllNPCS, FACING, NEAREST, FOLLOWER
		 * @param xDist - distance from player - used for FACING
		 * @param yDist - vertical distance from player - used for FACING
		 * @return vector of NPCs
		 */
		public function getNPCs( type:String, xDist:Number = 520, yDist = 48 ):Vector.<Entity>
		{
			var npcs:Vector.<Entity> = new Vector.<Entity>();
			
			// get player direction
			var player:Entity = shellApi.player;
			var spatial:Spatial = player.get(Spatial);
			var dir:Number = 1; // default facing right
			// if facing left
			if (spatial.scaleX > 0)
				dir = -1;
			
			// get each char
			var nodeList:NodeList = super.systemManager.getNodeList( CharacterUpdateNode );
			for( var node : CharacterUpdateNode = nodeList.head; node; node = node.next )
			{
				var npc:Entity = node.entity;
				
				// skip if no look
				if (SkinUtils.getLook(npc, false) == null)
					continue;
				
				// if not all, then skip player
				if( (type != ALL) && (npc == player) )
					continue;
				
				// skip mannequins
				if (node.character.variant == CharacterCreator.VARIANT_MANNEQUIN)
					continue;
				
				// exclude pop follower if not ALLNPCS or FOLLOWER
				var npcID:Id = npc.get(Id);
				if ((type != FOLLOWER) && (type != ALLNPCS) && (npcID) && (npcID.id.indexOf("popFollower") == 0))
					continue;
				else
				{
					switch (type)
					{
						case FACING: // if only those the avatar is facing
							var npcSpatial:Spatial = npc.get(Spatial);
							// if within distance and direction and close vertically, then add to array
							var testDistance:Number = dir * (npcSpatial.x - spatial.x);
							if ((testDistance > 0) && (testDistance < xDist) && (Math.abs( spatial.y - npcSpatial.y ) < yDist ))
								npcs.push(npc);
							break;
						case NEAREST: // if near avatar
							npcSpatial = npc.get(Spatial);
							// if within distance and direction and close vertically, then add to array
							if ((Math.abs(npcSpatial.x - spatial.x) < xDist) && (Math.abs( spatial.y - npcSpatial.y ) < yDist ))
								npcs.push(npc);
							break;
						case FOLLOWER: // if pop follower
							if ((npcID) && (npcID.id.indexOf("popFollower") == 0))
							{
								npcs.push(npc);
								return npcs;
							}
							break;
						default:
							npcs.push(npc);
							break;
					}
				}
			}
			
			return npcs;
		}
		
		/**
		 * Returns all characters in scene
		 * If npcOnly is true the player will not be return with the list.
		 */
		public function getCharactersInScene( npcOnly:Boolean = true ):Vector.<Entity>
		{
			var charsInView:Vector.<Entity>;
			
			var nodeList:NodeList = super.systemManager.getNodeList( CharacterUpdateNode );
			for( var node : CharacterUpdateNode = nodeList.head; node; node = node.next )
			{
				if( npcOnly && node.entity.get(Player) )
				{
					continue;
				}
				
				if( !charsInView )	{ charsInView = new Vector.<Entity>(); }			
				charsInView.push( node.entity )
			}
			
			return charsInView;
		}
		
		////////////////////////////////////////////////////////////////////
		/////////////////////////////// LOADING ////////////////////////////
		////////////////////////////////////////////////////////////////////
		
		/**
		 * NOTE: this can only prepare one batch of npcs at a time
		 * if multiple waves of npcs need to be prepared, this should be called after each wave is complete
		 * @param event - event that will trigger character update (via CharacterUpdateSystem)
		 * @param loadedCallback - handler to be called once all characters effected by event have completed loading
		 */
		public function addHandlerForCharactersUpdatedByEvent( event:String, loadedCallback:Function ):void
		{
			_charsLoadingById.length = 0;
			var nodeList:NodeList = systemManager.getNodeList( CharacterUpdateNode );
			var char:Character;
			for( var node : CharacterUpdateNode = nodeList.head; node; node = node.next )
			{
				char = node.character;
				if( char.hasDormantEvent(event) )
				{
					node.character.loadComplete.addOnce( Command.create(characterLoadedByEvent, node.id.id, char, event, loadedCallback ) );
					_charsLoadingById.push(node.id.id);
				}
			}
		}
		
		private function characterLoadedByEvent( charId:String, char:Character, event:String, loadedCallback:Function = null ):void
		{
			// check all characters, remove charComplete
			for ( var i:uint = 0; i < _charsLoadingById.length; i++  )
			{
				if ( _charsLoadingById[i] == charId )
				{
					if( char.event == event )
					{
						_charsLoadingById.splice( i, 1 );
						break;
					}
					else
					{
						char.loadComplete.addOnce( Command.create(characterLoadedByEvent, charId, char, event ) );
					}
				}
			}
			
			// if all character entities that need loading have loaded, dispatch loadComplete
			// RLH: npc friend bitmap char triggers this function immediately (nothing to load yet)
			// so sometimes the callback function gets dispatched too soon, before the other chars have been loaded
			if ( _charsLoadingById.length == 0 )
			{
				if( loadedCallback != null ) { loadedCallback(); }
			}
		}
		
		/**
		 * Add to list of loading characters.
		 * When all characters have finished loading CharacterGroup will dispatch _charactersLoaded
		 * @param charEntity
		 * @param loadedCallback - Function called when character entity has finished loading, called with params [ Entity ]
		 */
		public function addLoadCheck( charEntity:Entity, loadedCallback:Function = null ):void
		{
			// if character has nextCharData, check for load complete
			var character:Character = charEntity.get( Character );
			if ( character != null )
			{
				if ( character.nextCharData )
				{
					var id:String = charEntity.get(Id).id;
					character.loadComplete.addOnce( Command.create(characterLoaded, charEntity, id ) );
					_charsLoadingById.push( id );
					// AD SPECIFIC :: hide npc friend
					// TODO :: Can probably move this somewhere else - bard
					if (charEntity.get(Id).id == "npc_friend") { charEntity.get(Display).visible = false; }
					if( loadedCallback != null )
					{
						character.loadComplete.addOnce( Command.create(loadedCallback, charEntity) );
					}
				}
			}
			else
			{
				var bitmapChar:BitmapCharacter = charEntity.get( BitmapCharacter );
				if( bitmapChar )
				{
					if ( bitmapChar.nextCharData )
					{
						id = charEntity.get(Id).id;
						bitmapChar.loadComplete.addOnce( Command.create(characterLoaded, charEntity, id ) );
						_charsLoadingById.push( id );
						
						// check if bitmapped npc friend
						var npcFriend:Boolean = (charEntity.get(Id).id == "npc_friend_bitmap");
						// if npc friend, then dispatch
						if (npcFriend)
							bitmapChar.loadComplete.dispatch();
						if( loadedCallback != null )
						{
							character.loadComplete.addOnce( Command.create(loadedCallback, charEntity) );
							// if npc friend, then dispatch
							if (npcFriend)
								character.loadComplete.dispatch();
						}
					}
				}
			}		
		}
		
		/**
		 * Check if all characters that have been loaded have been completed....
		 */
		private function characterLoaded( charEntity:Entity, charId:String ):void
		{
			// check all characters, remove charComplete
			for ( var i:uint = 0; i < _charsLoadingById.length; i++  )
			{
				if ( _charsLoadingById[i] == charId )	//TODO :: This might need work
				{
					_charsLoadingById.splice( i, 1 );
					break;
				}
			}
			
			var character:Character = charEntity.get(Character);
			if ((character != null) && (character.nextCharData != null))
			{
				var limbList:Array = [CharUtils.LEG_FRONT, CharUtils.LEG_BACK, CharUtils.ARM_FRONT, CharUtils.ARM_BACK];
				// set line thickness
				if (character.nextCharData.lineThickness != 0)
				{
					var lineThickness:Number = character.nextCharData.lineThickness;
					for each (var part:String in limbList)
					{
						var npcPart:Entity = CharUtils.getPart( charEntity, part );
						if (npcPart != null)
							npcPart.get(Line).lineWidth = lineThickness;
					}
				}
				// if not darkening
				if (character.nextCharData.noDarken)
				{
					for each (part in limbList)
					{
						// get part entity and set darken percent to 0
						var partEnt:Entity = SkinUtils.getSkinPartEntity(charEntity, part);
						if (partEnt != null)
						{
							var colorSet:ColorSet = partEnt.get(ColorSet);
							colorSet.darkenPercent = 0;
							colorSet.invalidate = true;
						}
					}
				}
			}
			
			// if all character entities that need loading have loaded, dispatch loadComplete
			// RLH: npc friend bitmap char triggers this function immediately (nothing to load yet)
			// so sometimes the callback function gets dispatched too soon, before the other chars have been loaded
			if (( _charsLoadingById.length == 0 ) && (charId != "npc_friend_bitmap"))
			{
				_charactersLoaded.dispatch();
			}
			else if (charId != "npc_friend")
			{
				
			}
		}
		
		private function createJumpIndicator(container:DisplayObjectContainer):void
		{
			var entity:Entity = new Entity();
			
			entity.add(new Spatial());
			entity.add(new JumpTargetIndicator());
			entity.add(new Id("jumpTargetIndicator"));
			
			super.shellApi.loadFile(super.shellApi.assetPrefix + "ui/toolTip/jumpTargetIndicator.swf", Command.create(addJumpIndicator, entity, container));
		}
		
		private function addJumpIndicator(asset:DisplayObjectContainer, entity:Entity, container:DisplayObjectContainer):void
		{
			container.addChild(asset);
			entity.add(new Display(asset));
			asset.mouseChildren = false;
			asset.mouseEnabled = false;
			BitmapTimelineCreator.convertToBitmapTimeline(entity);
			super.addEntity(entity);
		}
		
		public function addCompleteListener( listener:Function, once:Boolean=false ):void 
		{
			if ( once ) {
				this._charactersLoaded.addOnce( listener );
			} else {
				this._charactersLoaded.add( listener );
			}
		}
		
		/** Flag determining if a npcs created through CharacterGroup will have tool tips */
		public var addToolTips:Boolean = true;
		
		public static const GROUP_ID:String = "characterGroup";
		public static const ADD_PLAYER:Boolean		= true;
		public static const DONT_ADD_PLAYER:Boolean	= false;
		public static const ADD_NPCS:Boolean		= true;
		public static const DONT_ADD_NPCS:Boolean	= false;
		
		public static const ALL:String = "ALL"; // all characters in scene including player's avatar but excluding follower
		public static const NPCS:String = "NPCS"; // all npcs in scene, not player's avatar
		public static const ALLNPCS:String = "AllNPCS"; // all npcs in scene, not player's avatar, includes pop follower
		public static const FACING:String = "FACING"; // all npcs in scene that the player is facing within certain distance
		public static const NEAREST:String = "NEAREST"; // all npcs in scene nearest player within certain distance
		public static const FOLLOWER:String = "FOLLOWER"; // the pop follower
		
		private var charStateSet:Vector.<Class> = new <Class>[ClimbState,game.systems.entity.character.states.DiveState,DuckState,FallState,HurtState,JumpState,LandState,PushState,RunState,SkidState,StandState,game.systems.entity.character.states.SwimState,WalkState];	//IdleState
		private var charTouchStateSet:Vector.<Class> = new <Class>[ClimbState,game.systems.entity.character.states.touch.DiveState,DuckState,FallState,HurtState,JumpState,LandState,PushState,RunState,SkidState,StandState,game.systems.entity.character.states.touch.SwimState,WalkState];	//IdleState
		private var creatureStateSet:Vector.<Class> = new <Class>[ClimbState,game.systems.entity.character.states.DiveState,FallState,HurtState,game.systems.entity.character.states.JumpState,LandState,PushState,game.systems.entity.character.states.RunState,game.systems.entity.character.states.SkidState,game.systems.entity.character.states.StandState,game.systems.entity.character.states.SwimState,WalkState];
		private var petStateSet:Vector.<Class> = new <Class>[ClimbState,FallState,game.systems.entity.character.states.JumpState,LandState,game.systems.entity.character.states.RunState,game.systems.entity.character.states.SkidState,game.systems.entity.character.states.StandState,game.systems.entity.character.states.SwimState,WalkState];
		private var movieClipStateSet:Vector.<Class> = new <Class>[MCDiveState, MCDuckState, MCFallState, MCHurtState, MCJumpState, MCLandState, MCRunState, MCStandState, MCSwimState, MCWalkState];
		
		private var _defaultAnims:Vector.<Class> = new <Class>[ Stand,Skid,Walk,Run,Jump,JumpSpin,Fall,Land,LandSpin,Spin,DuckDown,DuckUp,DuckSpin,DuckSpinUp,Climb,ClimbDown,Hurt,Swim,SwimTread,SwimLand,SwimLandSpin ];
		private var _charactersLoaded:Signal;
		private var _targetGroup:Group;
		private var _charsLoadingById:Vector.<String>;
		private var _bitmapCharacterCreator:BitmapCharacterCreator;
		private var _characterCreator:CharacterCreator;
		public function get characterCreator():CharacterCreator { return _characterCreator; }
		private var _lookConverter:LookConverter;
		private var _stateCreator:FSMStateCreator;
		private var _characterContainer:DisplayObjectContainer;
		private var _npcParser:NpcParser;
	}
}