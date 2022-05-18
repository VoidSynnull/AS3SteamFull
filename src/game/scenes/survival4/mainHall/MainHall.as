package game.scenes.survival4.mainHall
{	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Motion;
	import engine.components.MotionBounds;
	import engine.components.Spatial;
	import engine.components.SpatialAddition;
	import engine.components.Tween;
	import engine.creators.InteractionCreator;
	
	import fl.motion.easing.Quadratic;
	
	import game.components.animation.FSMControl;
	import game.components.entity.AlertSound;
	import game.components.entity.Dialog;
	import game.components.entity.NPCDetector;
	import game.components.entity.Sleep;
	import game.components.entity.character.CharacterMotionControl;
	import game.components.entity.collider.BitmapCollider;
	import game.components.entity.collider.PlatformCollider;
	import game.components.entity.collider.SceneCollider;
	import game.components.entity.collider.ZoneCollider;
	import game.components.hit.CurrentHit;
	import game.components.hit.Door;
	import game.components.hit.Platform;
	import game.components.hit.ValidHit;
	import game.components.hit.Wall;
	import game.components.motion.Destination;
	import game.components.motion.Edge;
	import game.components.motion.MotionThreshold;
	import game.components.motion.Navigation;
	import game.components.motion.SceneObjectMotion;
	import game.components.motion.ShakeMotion;
	import game.components.motion.Threshold;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.Timeline;
	import game.creators.scene.SceneItemCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.animation.entity.character.Laugh;
	import game.data.animation.entity.character.PourPitcher;
	import game.data.animation.entity.character.Pull;
	import game.data.animation.entity.character.Sneeze;
	import game.data.animation.entity.character.Think;
	import game.data.scene.DoorData;
	import game.data.scene.characterDialog.DialogData;
	import game.particles.FlameCreator;
	import game.scene.template.ItemGroup;
	import game.scenes.custom.AdMiniBillboard;
	import game.scenes.survival4.grounds.Grounds;
	import game.scenes.survival4.guestRoom.GuestRoom;
	import game.scenes.survival4.shared.Survival4Scene;
	import game.systems.SystemPriorities;
	import game.systems.entity.NPCDetectionSystem;
	import game.systems.entity.character.states.CharacterState;
	import game.systems.hit.ItemHitSystem;
	import game.systems.motion.MotionThresholdSystem;
	import game.systems.motion.SceneObjectMotionSystem;
	import game.systems.motion.ShakeMotionSystem;
	import game.systems.motion.ThresholdSystem;
	import game.ui.elements.DialogPicturePopup;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.MotionUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TimelineUtils;
	
	import org.flintparticles.twoD.zones.RectangleZone;
	
	public class MainHall extends Survival4Scene
	{
		private const RANDOM:String = 	"random";
		private const SIZZLE:String =	"sizzle";
		private const ROLL:String =		"roll";
		private const DOOR_OPEN:String =	"doorOpened";
		
		private var _paintingDisturbed:Boolean = false;
		private var _flameCreator:FlameCreator;
		private var _addressingPanel:Boolean = false;
		private var _usedCandle:Boolean = false;
		private var _locked:Boolean = false;
		private var _caught:Boolean = false;
		private var _atAttention:Boolean = false;
		private var _firePutOut:Boolean = false;
		private var _behindWall:Boolean = false;
		private var _thinkLoop:int = 0;
		private var _playerThinkLoop:int = 0;
		private var _pulls:int = 0;
		
		public function MainHall()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/survival4/mainHall/";
			
			super.init(container);
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();
		}
		
		override protected function addCharacterDialog(container:Sprite):void
		{
		//	addSecurityDialog();
			super.addCharacterDialog(container);
		}
		
		override public function destroy():void
		{
			shellApi.eventTriggered.remove( eventTriggers );
			super.destroy();
		}
		
		// all assets ready
		override public function loaded():void
		{
			var dialog:Dialog;
			var door:Entity;
			var doors:Array;
			var itemGroup:ItemGroup = super.getGroupById( ItemGroup.GROUP_ID ) as ItemGroup;
			var name:String;
			var painting:Entity;
			var sceneInteraction:SceneInteraction;
			var securityPanel:Entity;
			var spatial:Spatial;
			var trophyRoomDoor:Entity;
			var winston:Entity = getEntityById( "winston" );
			var vanBuren:Entity = getEntityById( "vanBuren" );
			
			if( shellApi.checkEvent( _events.WELCOME ))
			{
				removeEntity( vanBuren );
			}
			
			super.loaded();
			
			var minibillboard:AdMiniBillboard = new AdMiniBillboard(this,super.shellApi, new Point(223, 512));	

			optimizeAssets();
			var entity:Entity = getEntityById( "hiddenWalls" );
			entity.remove( Wall );

			addSystem( new ThresholdSystem(), SystemPriorities.update );
			addSystem( new ShakeMotionSystem(), SystemPriorities.move ); 
			
			if(!super.getSystem( ItemHitSystem ))	// items require ItemHitSystem, add system if not yet added
			{
				var itemHitSystem:ItemHitSystem = new ItemHitSystem();
				super.addSystem( itemHitSystem, SystemPriorities.resolveCollisions );
				
			}
			itemHitSystem.gotItem.add( itemGroup.itemHit );
			
			super.shellApi.eventTriggered.add( eventTriggers );
			
			_alertSystem.triggered.removeAll();
			_alertSystem.triggered.add( mainAlertSounded );
			
			positionMooseHead();
			setupFire();
			
			if( !shellApi.checkEvent( _events.WELCOME ))
			{
				SceneUtil.lockInput( this );
				CharUtils.lockControls( player );
				
				CharUtils.moveToTarget( vanBuren, 1350, 980, true, turnToPlayer );
				var characterMotion:CharacterMotionControl = vanBuren.get( CharacterMotionControl );
				characterMotion.maxVelocityX = 200;
				
				CharUtils.moveToTarget( player, 1100, 1000 );
				
				characterMotion = player.get( CharacterMotionControl );
				characterMotion.maxVelocityX = 200;
			}
			
			if( shellApi.checkEvent( _events.ATE_MEAT ))
			{
				var detector:NPCDetector = new NPCDetector( 500 );
				detector.detected.addOnce( playerDetected );
				
				if( winston )
				{
					winston.add( detector ).add( new CharacterMotionControl());
					characterMotion = winston.get( CharacterMotionControl );
					characterMotion.maxVelocityX = 100;
					
					var sleep:Sleep = winston.get( Sleep );
					if( sleep )
					{
						sleep.ignoreOffscreenSleep = true;
						winston.ignoreGroupPause = true;
						winston.managedSleep = true;
					}
					else
					{
						removeEntity( winston );
					}
					
					addSystem( new NPCDetectionSystem(), SystemPriorities.resolveCollisions );
				}
				
				trophyRoomDoor = getEntityById( "doorTrophy" );
				sceneInteraction = trophyRoomDoor.get( SceneInteraction );
				sceneInteraction.reached.removeAll();
				
				// NOTE: this overrides any ad scenes betwwen the main hnall and trophy room
				if( !shellApi.checkEvent( _events.TROPHY_ROOM_UNLOCKED ))
				{
					sceneInteraction.reached.add( trophyRoomLocked );
				}
				else
				{
					sceneInteraction.reached.add( toTheTrophyRoom );
				}
			}
			
			else
			{
				doors = [ "doorGuest", "doorVanBuren" ];	
				
				for each( name in doors )
				{
					door = getEntityById( name );
					sceneInteraction = door.get( SceneInteraction );
					sceneInteraction.reached.removeAll();
					sceneInteraction.reached.add( wantToGoHome );	
				}
				
				dialog = winston.get( Dialog );
				
				dialog.setCurrentById( "dinner" );
				dialog.complete.add( faceLeft );
			}
						
			securityPanel = getEntityById( "securityInteraction" );
			sceneInteraction = securityPanel.get( SceneInteraction );
			
			securityPanel.add( new Edge( 30, 20, 30, 20 ));
			dialog = securityPanel.get( Dialog );
			dialog.faceSpeaker = false;
			dialog.dialogPositionPercents = new Point( 0, .75 );
			
			if( !shellApi.checkEvent( _events.CODE_ENTERED ))
			{
				sceneInteraction.reached.add( askForPassword );
				
				door = getEntityById( "doorGrounds" );
				sceneInteraction = door.get( SceneInteraction );
				sceneInteraction.reached.removeAll();
				sceneInteraction.reached.add( tryTheDoor );		
			}
			else if( !shellApi.checkEvent( _events.TALLY_HO_DOWN ))
			{
				sceneInteraction.reached.add( askForTallyHo );
				
				door = getEntityById( "doorGrounds" );
				sceneInteraction = door.get( SceneInteraction );
				sceneInteraction.reached.removeAll();
				sceneInteraction.reached.add( tryTheDoor );		
			}
			else
			{
				securityPanel.remove( Interaction );
				securityPanel.remove( SceneInteraction );
				ToolTipCreator.removeFromEntity( securityPanel );
			}
		}
			
		/**
		 * 		UTILITIES AND SCENE SETUP
		 */
		private function optimizeAssets():void
		{
			this.createBitmap(this._hitContainer["fireplace"], 1);
			
			// MOOSE HEAD
			var asset:MovieClip = _hitContainer[ "bullmoose" ];
			var clip:MovieClip = asset[ "content" ];
			DisplayUtils.convertToBitmapSprite( clip, null, 2 );
			clip.mouseEnabled = false;
			clip.mouseChildren = false;
			
			var bullmoose:Entity = EntityUtils.createSpatialEntity( this, asset );
			var shakeMotion:ShakeMotion = new ShakeMotion( new RectangleZone( -5, -5, 5, 5 ));
			shakeMotion.speed = .096;
			shakeMotion.active = false;
			
			bullmoose.add( new Id( "bullmoose" )).add( new Tween()).add( shakeMotion ).add( new SpatialAddition());
			_audioGroup.addAudioToEntity( bullmoose );
			
			// TRIGGER CANDLE
			asset = _hitContainer[ "candle" ];
			clip = asset[ "content" ];
			DisplayUtils.convertToBitmapSprite( clip, null, 2 );
			
			var candle:Entity = EntityUtils.createMovingEntity( this, asset );
			candle.add( new Id( "candleTrigger" ));
			InteractionCreator.addToEntity( candle, [InteractionCreator.CLICK]);
			ToolTipCreator.addToEntity( candle );
			
			var sceneInteraction:SceneInteraction = new SceneInteraction();
			sceneInteraction.minTargetDelta = new Point( 15, 100 );
			sceneInteraction.reached.add( approachCandle );
			candle.add( sceneInteraction );
			_audioGroup.addAudioToEntity( candle );
			
			// STONE BLOCKING HIDDEN PATHWAY
			var display:Display = getEntityById( "hiddenPassage" ).get( Display );
			display.displayObject.mouseEnabled = false;
			display.displayObject.mouseChildren = false;
			
			asset = display.displayObject[ "firePath" ];
			clip = asset[ "content" ];
			DisplayUtils.convertToBitmapSprite( clip, null, 2 );
			clip.mouseEnabled = false;
			clip.mouseChildren = false;
			
			var pathBlock:Entity = EntityUtils.createMovingEntity( this, asset );
			pathBlock.add( new Id( "pathBlock" ));
			_audioGroup.addAudioToEntity( pathBlock );
			
			// PAINTING BLOCKING UPPER EXIT TO HIDDEN PATHWAY
			asset = _hitContainer[ "painting" ];
			clip = asset[ "content" ];
			DisplayUtils.convertToBitmapSprite( clip, null, 2 );
			
			var painting:Entity = EntityUtils.createMovingEntity( this, asset );
			painting.add( new Id( "painting" ));
			_audioGroup.addAudioToEntity( painting );
			
			// TROPHY ROOM KEY
			asset = _hitContainer[ "trophyKey" ];
			if( !shellApi.checkItemEvent( _events.TROPHY_ROOM_KEY ))
			{
				clip = asset[ "content" ];
				DisplayUtils.convertToBitmapSprite( clip, null, 2 );
				
				var key:Entity = EntityUtils.createSpatialEntity( this, asset );
				key.add( new Id( "trophyRoomKey" ));
			}
			else
			{
				_hitContainer.removeChild( asset );
			}
			
			// HORN LOGIC
			var horn:Entity = getEntityById( "hornInteraction" );
			sceneInteraction = horn.get( SceneInteraction );
			sceneInteraction.validCharStates = new Vector.<String>;
			sceneInteraction.validCharStates.push( CharacterState.STAND, CharacterState.WALK );
			sceneInteraction.reached.add( getInPosition );
			_audioGroup.addAudioToEntity( horn );
			
			// SECURITY PANEL
			asset = _hitContainer[ "securityPanel" ];
			clip = asset[ "content" ];
			DisplayUtils.convertToBitmapSprite( clip, null, 2 );
			clip.mouseEnabled = false;
			clip.mouseChildren = false;
			
			// VOICE LOCK
			var voiceLock:Entity = TimelineUtils.convertClip( asset.voiceLock, this );
			voiceLock.add( new Id( "voiceLockScene" ));
			_audioGroup.addAudioToEntity( voiceLock );
			var timeline:Timeline;
			
			if( shellApi.checkEvent( _events.TALLY_HO_DOWN ))
			{
				timeline = voiceLock.get( Timeline );
				timeline.gotoAndStop( 1 );
			}
			
				// KEY LOCK
			var keyLock:Entity = TimelineUtils.convertClip( asset.keyLock, this );
			keyLock.add( new Id( "keyLockScene" ));
			
			if( shellApi.checkEvent( _events.CODE_ENTERED ))
			{
				timeline = keyLock.get( Timeline );
				timeline.gotoAndStop( 1 );
			}
			
				// MASTER LOCK
			var masterLock:Entity = TimelineUtils.convertClip( asset.masterLock, this );
			masterLock.add( new Id( "masterLockScene" ));
			_audioGroup.addAudioToEntity( masterLock );
			
			if( shellApi.checkEvent( _events.TALLY_HO_DOWN ) && shellApi.checkEvent( _events.CODE_ENTERED ))
			{
				timeline = masterLock.get( Timeline );
				timeline.gotoAndStop( 1 );
			}
		}
		
		private function positionMooseHead():void
		{
			var bullmoose:Entity = getEntityById( "bullmoose" );
			var creator:SceneItemCreator = new SceneItemCreator();
			var key:Entity = getEntityById( "trophyRoomKey" );
			var creaky0:Entity = getEntityById( "creaky0" );
			var creaky1:Entity = getEntityById( "creaky1" );
			var creaky2:Entity = getEntityById( "creaky2" );
			var creaky3:Entity = getEntityById( "creaky3" );
			var spatial:Spatial = bullmoose.get( Spatial );
			
			this.addSystem(new SceneObjectMotionSystem());
			
			if( shellApi.checkEvent( _events.MOOSE_FACING_ + "1" ))
			{
				removeEntity( creaky0 );
				spatial.rotation = 45;
				
				if( shellApi.checkEvent( _events.MOOSE_FACING_ + "2" ))
				{
					removeEntity( creaky1 );
					spatial.rotation = 90;
					
					if( shellApi.checkEvent( _events.MOOSE_FACING_ + "3" ))
					{						
						spatial.x = 1580;
						spatial.y = 910;
						spatial.rotation = 375;
						
						removeEntity( creaky2 );
						removeEntity( creaky3 );
						
						if( key )
						{
							creator.make( key, new Point( 25, 100 ));
						}
					}
						
					else
					{
						creaky2.add( new AlertSound());
						creaky3.add( new AlertSound());
					}
				}
					
				else
				{
					creaky1.add( new AlertSound());
					creaky2.add( new AlertSound());
					creaky3.remove( Platform );
				}
			}
				
			else
			{
				creaky0.add( new AlertSound());
				creaky1.remove( Platform );
				creaky2.remove( Platform );
				creaky3.remove( Platform );
			}
		}
		
		private function setupFire():void
		{
			_flameCreator = new FlameCreator();
			_flameCreator.setup( this, super._hitContainer[ "flame" + 1 ], null, onFlameLoaded );
		}
		
		private function onFlameLoaded():void
		{
			var audio:Audio;
			var audioRange:AudioRange;
			var clip:MovieClip;
			var flameEntity:Entity;
			var spatial:Spatial;
			
			for( var number:uint = 0; number < 2; number ++ )
			{
				clip = super._hitContainer[ "flame" + number ];
				flameEntity = _flameCreator.createFlame( this, clip, true );
				flameEntity.add( new Id( "flame" + number ));
				
				if( number == 0 )
				{
					flameEntity.add( new AudioRange( 600, .02, 2 ));
					_audioGroup.addAudioToEntity( flameEntity );
				
					
					audio = flameEntity.get( Audio );
					audio.playCurrentAction( RANDOM );
				}
			}
			
			clip = _hitContainer[ "candle" ][ "flame2" ];
			flameEntity = _flameCreator.createFlame( this, clip, true );
			flameEntity.add( new AudioRange( 300, .01, 1 )).add( new Id( "flame2" ));
		}
	
		private function faceLeft( dialogData:DialogData ):void
		{
			var winston:Entity = getEntityById( "winston" );
			CharUtils.setDirection( winston, false );
		}

		private function turnToPlayer( vanBuren:Entity ):void
		{
			CharUtils.setDirection( vanBuren, false );
			
			var dialog:Dialog = vanBuren.get( Dialog );
			dialog.faceSpeaker = false;
			
			dialog.sayById( "lucky" );
		}
		
		private function removeVanBuren( vanBuren:Entity ):void
		{			
			removeEntity( vanBuren );
		}
		
		/**
		 * 		EVENT HANDLER
		 */
		private function eventTriggers( event:String, save:Boolean = true, init:Boolean = false, removeEvent:String = null ):void
		{
			var characterMotion:CharacterMotionControl;
			var door:Entity;
			var dialog:Dialog;
			var interaction:Interaction;
			var masterLock:Entity;
			var sceneInteraction:SceneInteraction;
			var timeline:Timeline;
			var vanBuren:Entity = getEntityById( "vanBuren" );
			
			switch( event )
			{
				case _events.VOICE_AUTHORIZATION:
					thoughtHandler();
					break;
				
				// VAN BUREN TO TROPHY ROOM
				case _events.TO_THE_TROPHIES:
					SceneUtil.lockInput( this, false );
					CharUtils.lockControls( player, false, false );
					shellApi.completeEvent( _events.WELCOME );
					
					characterMotion = player.get( CharacterMotionControl );
					characterMotion.maxVelocityX = 800;
					
					CharUtils.moveToTarget( vanBuren, 2582, 980, true, removeVanBuren );
				 	break;
				
				// VAN BUREN REFUSING TO LET YOU GO HOME
				case _events.NONSENSE_BOY:
					CharUtils.setAnim( vanBuren, Laugh ); 
					
					dialog = vanBuren.get( Dialog );
					dialog.sayById( "nonsense" );
					break;
				
				// PUTTING OUT THE FIREPLACE
				case _events.USE_FULL_PITCHER:				
					var flames:Entity = getEntityById( "flame0" );
					if( flames )
					{
						if( !_locked ) 
						{
							SkinUtils.setSkinPart( player, SkinUtils.ITEM, "survival_4_pitcher" );
							InteractionCreator.addToEntity( flames, [InteractionCreator.CLICK]);
							
							sceneInteraction = new SceneInteraction()
							sceneInteraction.reached.addOnce( quellTheFlames );
							sceneInteraction.validCharStates = new Vector.<String>;
							sceneInteraction.validCharStates.push( CharacterState.STAND, CharacterState.WALK );
							
							flames.add( sceneInteraction );
							
							interaction = flames.get( Interaction );
							interaction.click.dispatch( flames );
						}
					}
					else
					{
						dialog = player.get( Dialog );
						dialog.sayById( "no_use" );
					}
					break;
				
				// FIREPLACE IS OUT AND HIDDEN PASSAGE HAS BEEN MOVED
				case _events.HIDDEN_PATH_OPEN:
					openPassage( "passageLower" );
					break;
				
				// HAVE TROPHY ROOM DOOR KEY, JUST NEED TO UNLOCK THE DOOR
				case _events.USE_TROPHY_ROOM_KEY:
					var trophyRoomDoor:Entity = getEntityById( "doorTrophy" );
					if( !shellApi.checkEvent( _events.TROPHY_ROOM_UNLOCKED ))
					{
						interaction = trophyRoomDoor.get( Interaction );
						
						sceneInteraction = trophyRoomDoor.get( SceneInteraction );
						sceneInteraction.reached.removeAll();
						sceneInteraction.validCharStates = new Vector.<String>;
						sceneInteraction.validCharStates.push( CharacterState.WALK, CharacterState.STAND );
						sceneInteraction.offsetX = -10;
						sceneInteraction.reached.add( unlockTrophyRoom );
						
						interaction.click.dispatch( trophyRoomDoor );
					}
					else
					{
						dialog = player.get( Dialog );
						dialog.sayById( "no_use" );
					}
					break;
				
				case _events.USE_TALLY_HO:
					if( !shellApi.checkEvent( _events.TALLY_HO_DOWN ))
					{
						dialog = getEntityById( "recording_entity" ).get( Dialog );
						dialog.complete.addOnce( tallyHoGiven );
					}
					break;
				
				case _events.CODE_ENTERED:
					var keyLock:Entity = getEntityById( "keyLockScene" );
					timeline = keyLock.get( Timeline );
					timeline.gotoAndStop( 1 );
					
					var securityPanel:Entity = getEntityById( "securityInteraction" );
					_addressingPanel = false;
					
					if( shellApi.checkEvent( _events.TALLY_HO_DOWN ))
					{
						ToolTipCreator.removeFromEntity( securityPanel );	
						sceneInteraction = securityPanel.get( SceneInteraction );
						sceneInteraction.reached.removeAll();
						
						interaction = securityPanel.get( Interaction );
						interaction.removeAll();
						
						masterLock = getEntityById( "masterLockScene" );
						timeline = masterLock.get( Timeline );
						timeline.gotoAndStop( 1 );
						
						door = getEntityById( "doorGrounds" );
						sceneInteraction = door.get( SceneInteraction );
						sceneInteraction.reached.removeAll();
						sceneInteraction.reached.add( toTheGrounds );	
					}
					
					else
					{
						sceneInteraction = securityPanel.get( SceneInteraction );
						sceneInteraction.reached.removeAll();
						sceneInteraction.reached.add( askForTallyHo );
					}
					break;
				
				case _events.USE_ARMORY_KEY:
					dialog = player.get( Dialog );
					dialog.sayById( "no_use" );
					break;
				
				case _events.USE_EMPTY_PITCHER:
					dialog = player.get( Dialog );
					dialog.sayById( "no_use" );
					break;
				
				case _events.USE_SPEAR:
					dialog = player.get( Dialog );
					dialog.sayById( "no_use" );
					break;
				
				case _events.USE_TAINTED_MEAT:
					dialog = player.get( Dialog );
					dialog.sayById( "no_use" );
					break;
				
				default:
					break;
			}
		}
				
		/**
		 * 		MOOSE HEAD INTERACTION LOGIC
		 */
		protected function mainAlertSounded():void
		{
			var creakyObject:Entity;
			var dialog:Dialog;
			var mooseHead:Entity = getEntityById( "bullmoose" );

			var shakeMotion:ShakeMotion = mooseHead.get( ShakeMotion );
			shakeMotion.active = true;
			
			if( !shellApi.checkEvent( _events.MOOSE_FACING_ + "2" ))
			{
				if( !shellApi.checkEvent( _events.MOOSE_FACING_ + "1" ))
				{
					if( !shellApi.checkEvent( _events.ATE_MEAT ))
					{						
						dialog = player.get( Dialog );
						dialog.sayById( "fragile" );
						
						creakyObject = getEntityById( "creaky0" );
						creakyObject.remove( Platform );
					}
					else
					{
						creakyObject = getEntityById( "creaky0" );
						creakyObject.remove( AlertSound );
						
						shellApi.triggerEvent( _events.MOOSE_FACING_ + "1", true );
					}
				}
				else
				{
					creakyObject = getEntityById( "creaky1" );
					creakyObject.remove( AlertSound );
					
					creakyObject = getEntityById( "creaky2" );
					creakyObject.remove( AlertSound );
					
					shellApi.triggerEvent( _events.MOOSE_FACING_ + "2", true );
				}
			}
			else
			{
				creakyObject = getEntityById( "creaky2" );
				creakyObject.remove( AlertSound );
				
				creakyObject = getEntityById( "creaky3" );
				creakyObject.remove( AlertSound );
				
				shellApi.triggerEvent( _events.MOOSE_FACING_ + "3", true );
			}
			
			SceneUtil.addTimedEvent( this, new TimedEvent( .5, 1, endMooseHeadShake ));
		}
		
		private function endMooseHeadShake():void
		{
			var creakyObject:Entity;
			var mooseHead:Entity = getEntityById( "bullmoose" );
			var spatialAddition:SpatialAddition = mooseHead.get( SpatialAddition );
			var shakeMotion:ShakeMotion = mooseHead.get( ShakeMotion );
			
			var motion:Motion = player.get( Motion );
			motion.velocity.y = 0;
			spatialAddition.x = spatialAddition.y = 0;
			shakeMotion.active = false;
			
			var tween:Tween = mooseHead.get( Tween );
			var spatial:Spatial = mooseHead.get( Spatial );
			
			if( shellApi.checkEvent( _events.MOOSE_FACING_ + "3" ))
			{				
				mooseHead.add( new ValidHit( "wood" ));
				mooseHead.add( new Edge( 70, 70, 70, 0 ));
				mooseHead.add( new BitmapCollider());
				mooseHead.add( new SceneCollider());
				mooseHead.add( new CurrentHit());
				mooseHead.add( new ZoneCollider());
				mooseHead.add( new MotionBounds( player.get( MotionBounds ).box ));
				
				motion 				= new Motion();
				motion.friction 	= new Point( 0, 0 );
				motion.maxVelocity 	= new Point( 1000, 1000 );
				motion.minVelocity 	= new Point( 0, 0 );
				motion.acceleration = new Point( 0, MotionUtils.GRAVITY );
				motion.velocity.x 	= 100;
				
				mooseHead.add( motion );
				
				var sceneObjectMotion:SceneObjectMotion = new SceneObjectMotion();
				sceneObjectMotion.rotateByPlatform = false;
				sceneObjectMotion.platformFriction = 10;
				mooseHead.add( sceneObjectMotion );
				
				var platformCollider:PlatformCollider = new PlatformCollider();
				mooseHead.add( platformCollider );
				
				var audio:Audio = mooseHead.get( Audio );
				audio.playCurrentAction( ROLL );
				
				var threshold:Threshold = new Threshold( "y", ">=" );
				threshold.threshold = 870;
				threshold.entered.add( mooseHeadCrash );
				mooseHead.add( threshold );
				
				for( var number:int = 0; number < 4; number++ )
				{
					creakyObject = getEntityById( "creaky" + number );
					if( creakyObject )
					{
						creakyObject.remove( Platform );
						removeEntity( creakyObject, true );
					}
				}
		
				spatial = player.get( Spatial );
				var destination:Destination = CharUtils.moveToTarget( player, spatial.x, 980, true );
				destination.ignorePlatformTarget = true;
			}
			
			else if( shellApi.checkEvent( _events.MOOSE_FACING_ + "2" ))
			{
				removeEntity( getEntityById( "creaky1" ));
				
				creakyObject = getEntityById( "creaky2" );
				creakyObject.remove( Platform );
				
				tween.to( spatial, 1, { rotation : 90, onComplete : updateMooseHead, ease : Quadratic.easeOut, onCompleteParams : [ getEntityById( "creaky3" )]});
			}
			
			else if( shellApi.checkEvent( _events.MOOSE_FACING_ + "1" ))
			{
				removeEntity( getEntityById( "creaky0" ));
				tween.to( spatial, 1, { rotation : 45, onComplete : updateMooseHead, ease : Quadratic.easeOut, onCompleteParams : [ getEntityById( "creaky1" ), getEntityById( "creaky2" )]});
			}
			
		}
		
		private function updateMooseHead( newPlatform1:Entity = null, newPlatform2:Entity = null ):void
		{
			if( newPlatform1 )
			{
				newPlatform1.add( new Platform()).add( new AlertSound());
			}
			if( newPlatform2 )
			{
				newPlatform2.add( new Platform()).add( new AlertSound());
			}
		}

		private function mooseHeadCrash():void
		{
			var mooseHead:Entity = getEntityById( "bullmoose" );
			mooseHead.remove( Threshold );				
			
			var audio:Audio = mooseHead.get( Audio );
			audio.playCurrentAction( RANDOM );
			
			var threshold:Threshold = new Threshold( "x", ">=" );
			threshold.threshold = 1560;
			threshold.entered.add( endMooseHeadRoll );
			mooseHead.add( threshold );
		}

		private function endMooseHeadRoll():void
		{
			var mooseHead:Entity = getEntityById( "bullmoose" );
			var spatial:Spatial = mooseHead.get( Spatial );
			mooseHead.remove( Motion );
			
			var tween:Tween = mooseHead.get( Tween );
			tween.to( spatial, .3, { x : spatial.x + 20, rotation : 375, ease : Quadratic.easeOut });
			
			var key:Entity = getEntityById( "trophyRoomKey" ); 
			var creator:SceneItemCreator = new SceneItemCreator();
			creator.make( key, new Point( 25, 100 ));
			
			var audio:Audio = mooseHead.get( Audio );
			audio.stopActionAudio( ROLL );
			
	//		CharUtils.lockControls( player, false, false );
		}
		
		/**
		 * 		HORN TO DISTRACT WINSTON
		 */
		private function getInPosition( player:Entity, horn:Entity ):void
		{
			if( !_atAttention )
			{
				var spatial:Spatial = horn.get( Spatial );
				CharUtils.moveToTarget( player, spatial.x + 40, spatial.y, false, blowThatHorn, new Point( 10, 10 ));
			}
		}
		
		private function blowThatHorn( player:Entity ):void
		{
			CharUtils.setDirection( player, false );
			CharUtils.setAnim( player, Sneeze );
			SceneUtil.lockInput( this );
		
			var timeline:Timeline = player.get( Timeline );
			timeline.handleLabel( "fire", holdTheNote );
		}
		
		private function holdTheNote():void
		{
			var horn:Entity = getEntityById( "hornInteraction" );
			var audio:Audio = horn.get( Audio );
			
			audio.playCurrentAction( RANDOM );
			
			var timeline:Timeline = player.get( Timeline );
			timeline.stop();
			
			SceneUtil.addTimedEvent( this, new TimedEvent( .5, 1, summonButler ));
		}
		
		private function summonButler():void
		{
			var timeline:Timeline = player.get( Timeline );
			timeline.play();
			
			var winston:Entity = getEntityById( "winston" );
			if( winston && shellApi.checkEvent( _events.ATE_MEAT ))
			{
				_atAttention = true;
				SceneUtil.lockInput( this );
				SceneUtil.setCameraTarget( this, winston, false, .05 );
				var dialog:Dialog = winston.get( Dialog );
				
				dialog.sayById( "startled" );
				dialog.complete.add( butlerHasBeenSummoned );
			}
			else
			{
				SceneUtil.lockInput( this, false );
			}
		}
		
		private function butlerHasBeenSummoned( dialogData:DialogData ):void
		{
			if( !_caught )
			{
				var winston:Entity = getEntityById( "winston" );
				
				SceneUtil.lockInput( this, false );
				SceneUtil.setCameraTarget( this, player, false, .05 );
				
				CharUtils.moveToTarget( winston, 1960, 486, true, butlerAtEndOfStairs );
			}
		}
		
		private function butlerAtEndOfStairs( winston:Entity ):void
		{
			if( !_caught )
			{				
				CharUtils.setAnim( winston, Think );
				var timeline:Timeline = winston.get( Timeline );
				
				timeline.labelReached.add( winstonThinkHandler );
			}
		}
		
		private function winstonThinkHandler( label:String ):void
		{
			if( !_caught )
			{
				if( label == "loop" )
				{
					_thinkLoop ++;
		
					if( _thinkLoop == 15 )
					{
						_thinkLoop = 0;
						var winston:Entity = getEntityById( "winston" );
						var timeline:Timeline = winston.get( Timeline );
						
						timeline.labelReached.removeAll();
						CharUtils.stateDrivenOn( winston );
						CharUtils.moveToTarget( winston, 2550, 486, true, butlerBackInPosition );
						
						var destination:Destination = winston.get( Destination );
						destination.setDirectionOnReached( "left" );
					}	
				}
			}
		}
		
		private function butlerBackInPosition( winston:Entity ):void
		{
			CharUtils.setDirection( winston, false );
			_atAttention = false;
			
			CharUtils.lockControls( winston );
		}
		
		/**
		 *  	HIDDEN PASSAGE LOGIC
		 */	
		private function openPassage( name:String ):void
		{			
			var trigger:Entity = EntityUtils.createSpatialEntity( this, _hitContainer[ name ]);
			InteractionCreator.addToEntity( trigger, [ InteractionCreator.CLICK ]);
			ToolTipCreator.addToEntity( trigger );
			
			var sceneInteraction:SceneInteraction = new SceneInteraction();
			if( name == "passageLower" )
			{
				sceneInteraction.minTargetDelta = new Point( 50, 100 );
			}
			else
			{
				sceneInteraction.minTargetDelta = new Point( 35, 100 );
			}
			
			if( _behindWall )
			{
				sceneInteraction.reached.add( outOfHiddenPassage );
			}
			else
			{
				sceneInteraction.reached.add( intoHiddenPassage );
			}
			
			trigger.add( sceneInteraction ).add( new Id( name ));
		}
		
		private function intoHiddenPassage( character:Entity, passage:Entity ):void
		{
			var display:Display;
			var id:Id = passage.get( Id );
			var layer:Entity;
			var name:String;
			var passageUpper:Entity = getEntityById( "passageUpper" )
			var painting:Entity = getEntityById( "painting" );
			var winston:Entity = getEntityById( "winston" );
			
			if( winston )
			{
				winston.remove( NPCDetector );
				
				if( _paintingDisturbed )//shellApi.checkEvent( _events.PAINTING_DISTURBED ))
				{
					var threshold:Threshold = new Threshold( "x", ">=", passageUpper, -25 );
					threshold.entered.addOnce( readdDetectorToButler );
					player.add( threshold );
				}
			}
			
			if( id.id == "passageLower" && !_firePutOut )
			{
				var dialog:Dialog = player.get( Dialog );
				dialog.sayById( "too_hot" );
			}
			
			else
			{
				if( id.id == "passageUpper" )
				{
					var fsmControl:FSMControl = player.get( FSMControl );
					fsmControl.setState( CharacterState.JUMP );
				}
				
				_behindWall = true;
				
				// SWITCH PLAYER CONTAINER LAYER
				layer = getEntityById( "hiddenPassage" );
				display = layer.get( Display );
				
				var pathBlock:Entity = this.getEntityById("pathBlock");
				var pathDisplay:DisplayObjectContainer = Display(pathBlock.get(Display)).displayObject;
				
				var index:int = pathDisplay.parent.getChildIndex(pathDisplay);
				var playerDisplay:Display = player.get( Display );
				playerDisplay.setContainer( pathDisplay.parent, index );
				
				// SWAP SCENE INTERACTIONS TO EXIT
				var passages:Array = [ "passageUpper", "passageLower" ];
				var sceneInteraction:SceneInteraction;
				
				for each( name in passages )
				{
					passage = getEntityById( name );
					if( passage )
					{
						sceneInteraction = passage.get( SceneInteraction );
						sceneInteraction.reached.removeAll();
						sceneInteraction.reached.add( outOfHiddenPassage );
					}
				}
				
				// UPDATE HITS
				var hit:Entity;
				var offHits:Array = [ "wood", "creaky0", "creaky1", "creaky2", "creaky3" ];
				
				for each( name in offHits )
				{
					hit = getEntityById( name );
					if( hit )
					{
						hit.remove( Platform );
					}
				}
				
				hit = getEntityById( "hiddenWalls" );
				hit.add( new Wall());
				
				if( !_paintingDisturbed )//!shellApi.checkEvent( _events.PAINTING_DISTURBED ))
				{
					InteractionCreator.addToEntity( painting, [ InteractionCreator.CLICK ]);
					sceneInteraction = new SceneInteraction();
					sceneInteraction.reached.add( moveThePainting );
					painting.add( sceneInteraction );
					
					ToolTipCreator.addToEntity( painting );
				}
			}
		}
		
		private function moveThePainting( player:Entity, painting:Entity ):void
		{
			ToolTipCreator.removeFromEntity( painting );
			_paintingDisturbed = true;//shellApi.triggerEvent( _events.PAINTING_DISTURBED, true );  
			
			var tween:Tween = new Tween();
			var spatial:Spatial = painting.get( Spatial );
			tween.to( spatial, 1, { x : spatial.x - 80 });
			
			painting.add( tween );
			painting.remove( Interaction );
			painting.remove( SceneInteraction );
			
			openPassage( "passageUpper" );
			
			var passageUpper:Entity = getEntityById( "passageUpper" );
			
			var threshold:Threshold = new Threshold( "x", ">=", passageUpper, -25 );
			threshold.entered.addOnce( readdDetectorToButler );
			player.add( threshold );
			
			var audio:Audio = painting.get( Audio );
			audio.playCurrentAction( RANDOM );
		}
		
		private function outOfHiddenPassage( character:Entity, passage:Entity ):void
		{
			var display:Display;
			var id:Id = passage.get( Id );
			var layer:Entity;
			var name:String;
			var winston:Entity = getEntityById( "winston" );
			
			if( winston )
			{
				var detector:NPCDetector = new NPCDetector( 500 );
				detector.detected.addOnce( playerDetected );
				winston.add( detector );
				
				player.remove( Threshold );
			}
			
			if( id.id == "passageLower" && !_firePutOut )
			{
				var dialog:Dialog = player.get( Dialog );
				dialog.sayById( "too_hot" );
			}
				
			else
			{
				if( id.id == "passageUpper" )
				{
					var fsmControl:FSMControl = player.get( FSMControl );
					fsmControl.setState( CharacterState.JUMP );
				}
				_behindWall = false;
				
				// SWITCH PLAYER CONTAINER LAYER
				layer = getEntityById( "interactive" );
				display = layer.get( Display );
				
				var playerDisplay:Display = player.get( Display );
				playerDisplay.setContainer( display.displayObject );
				
				// SWAP SCENE INTERACTIONS TO ENTER
				var passages:Array = [ "passageUpper", "passageLower" ];
				var sceneInteraction:SceneInteraction;
				
				for each( name in passages )
				{
					passage = getEntityById( name );
					if( passage )
					{
						sceneInteraction = passage.get( SceneInteraction );
						sceneInteraction.reached.removeAll();
						sceneInteraction.reached.add( intoHiddenPassage );
					}
				}
				
				// UPDATE HITS
				var hit:Entity;
				var onHits:Array = [ "wood", "creaky0", "creaky1", "creaky2", "creaky3" ];
				
				for each( name in onHits )
				{
					hit = getEntityById( name );
					if( hit )
					{
						if( name.indexOf( "creaky" ) == -1 )
						{ 
							hit.add( new Platform());
						}
						else if(( name == "creaky0" || name == "creaky1" ) && !shellApi.checkEvent( _events.MOOSE_FACING_ + "1" ))
						{
							hit.add( new Platform());
						}
						else if( name == "creaky2" && (( shellApi.checkEvent( _events.MOOSE_FACING_ + "1" ) || shellApi.checkEvent( _events.MOOSE_FACING_ + "2" ))))
						{
							hit.add( new Platform());
						}
						else if( name == "creaky3" && shellApi.checkEvent( _events.MOOSE_FACING_ + "2" ))
						{
							hit.add( new Platform());
						}
					}
				}
				
				hit = getEntityById( "hiddenWalls" );
				hit.remove( Wall );
			}
		}
		
		/**
		 * 		CANDLE LOGIC
		 */ 
		private function approachCandle( player:Entity, candle:Entity ):void
		{
			if( !_usedCandle && !_locked )
			{
				// FLAG SO IT ONLY CAN RUN ONCE AT A TIME AND CANNOT QUEUE AFTER ITSELF
				_usedCandle = true;
				_locked = true;
				
				CharUtils.setDirection( player, false );
				CharUtils.setAnim( player, Pull );
				var spatial:Spatial = player.get( Spatial );
				var tween:Tween = new Tween();
				tween.to( spatial, 3, { x : spatial.x + 20, ease : Quadratic.easeInOut });
				player.add( tween );
				
				// REPOSITION WICK, PATH BLOCK AND TRIGGER CANDLE
				spatial = candle.get( Spatial );
				tween = new Tween();
				tween.to( spatial, 3, { rotation : 45, ease : Quadratic.easeInOut, onComplete : endPull, onCompleteParams : [ candle ]});
				candle.add( tween );
				
				var wick:Entity = getEntityById( "flame2" );
				spatial = wick.get( Spatial );
				tween = new Tween();
				tween.to( spatial, 3, { rotation : -45, ease : Quadratic.easeInOut });
				wick.add( tween );
				
				var path:Entity = getEntityById( "pathBlock" );
				spatial = path.get( Spatial );
				tween = new Tween();
				tween.to( spatial, 3, { x : spatial.x - 140, ease : Quadratic.easeInOut });
				path.add( tween );	
				var audio:Audio = path.get( Audio );
				audio.playCurrentAction( RANDOM );
				
				audio = candle.get( Audio );
				audio.playCurrentAction( RANDOM );
				
				ToolTipCreator.removeFromEntity( candle );
			}
		}
		
		private function endPull( candle:Entity ):void
		{
			CharUtils.stateDrivenOn( player );
			
			candle.remove( SceneInteraction );
			candle.remove( Interaction );
			
			shellApi.triggerEvent( _events.HIDDEN_PATH_OPEN );   // true
			
			var path:Entity = getEntityById( "pathBlock" );
			var audio:Audio = path.get( Audio );
			audio.stopActionAudio( RANDOM );
			
			_locked = false;
		}
		
		/**
		 * 		FIREPLACE FLAMES LOGIC
		 */ 
		private function quellTheFlames( player:Entity, flames:Entity ):void
		{
			_locked = true;
			CharUtils.setAnim( player, PourPitcher );
			var timeline:Timeline = player.get( Timeline );
			timeline.labelReached.add( animeHandler );
			
			var spatial:Spatial = flames.get( Spatial );
			var tween:Tween = new Tween();
			tween.to( spatial, 3, { scale : spatial.scale * .1, ease : Quadratic.easeOut, onComplete : putThemOut, onCompleteParams : [ flames ]});
			
			flames.add( tween );
		}
		
		private function animeHandler( event:String ):void
		{
			var timeline:Timeline;
			
			var flames:Entity = getEntityById( "flame0" );
			var audio:Audio = flames.get( Audio );
			
			if( event == "trigger" )
			{
				audio.playCurrentAction( SIZZLE );
			}
			if( event == "ending" )
			{
				SkinUtils.setSkinPart( player, SkinUtils.ITEM, "empty" );
				timeline = player.get( Timeline );
				timeline.labelReached.removeAll();
				
				audio.stopAll( "effects" );
			}
		}
		
		private function putThemOut( flames:Entity ):void
		{
			removeEntity( flames );
			
			shellApi.triggerEvent( _events.FIRE_PUT_OUT );//, true );
			_firePutOut = true;
			_locked = false;
		}
		
		/**
		 * 		CAUGHT BY BUTLER
		 */ 	
		private function playerDetected( player:Entity = null ):void
		{
			SceneUtil.lockInput( this, true );
			CharUtils.lockControls( player );
			MotionUtils.zeroMotion( player );
					
			var hit:Entity = getEntityById( "hiddenWalls" );
			hit.remove( Wall );
			
			var winston:Entity = getEntityById( "winston" );
			CharUtils.stateDrivenOn( winston );
			_thinkLoop = 0;
			
			SceneUtil.setCameraTarget( this, winston );
			var navigation:Navigation = winston.get( Navigation );
			if( navigation )
			{
				winston.remove( Navigation );
				winston.remove( Destination );
			}
			
			var playerSpatial:Spatial = player.get( Spatial );
			var winstonSpatial:Spatial = winston.get( Spatial );
			
			var characterMotion:CharacterMotionControl = winston.get( CharacterMotionControl );
			characterMotion.maxVelocityX = 200;
						
			var moveToSpot:Number = player.get( Spatial ).x - winston.get( Spatial ).x <= 0 ? 200 : -200;
			
			CharUtils.moveToTarget( winston, player.get( Spatial ).x + moveToSpot, winstonSpatial.y, true, suchDisappoint )
			_caught = true;
		}
		
		private function readdDetectorToButler():void
		{
			var winston:Entity = getEntityById( "winston" );
			
			if( winston )
			{
				var detector:NPCDetector = new NPCDetector( 500 );
				detector.detected.addOnce( playerDetected );
				winston.add( detector );
				
				var threshold:Threshold = player.get( Threshold );
				threshold.operator = "<=";
				threshold.entered.addOnce( removeButlerDetect );
			}
		}
		
		private function removeButlerDetect():void
		{
			var winston:Entity = getEntityById( "winston" );
			
			if( winston )
			{
				winston.remove( NPCDetector );
				
				var threshold:Threshold = player.get( Threshold );
				threshold.operator = ">=";
				threshold.entered.addOnce( readdDetectorToButler );
			}
		}
		
		private function suchDisappoint( winston:Entity ):void
		{
			var dialog:Dialog = winston.get( Dialog );
			dialog.sayById( "caught" );
			
			dialog.complete.add( caughtByButler );
			winston.remove( Navigation );
			winston.remove( Destination );
			
			var timeline:Timeline = winston.get( Timeline );
			timeline.labelReached.removeAll();
		}
		
		private function caughtByButler( dialogData:DialogData ):void
		{
			SceneUtil.lockInput( this, false, false );
			var butlerPopup:DialogPicturePopup = new DialogPicturePopup( overlayContainer );
			butlerPopup.updateText( "You were caught sneaking around! Back to your room...", "Try Again" );
			butlerPopup.configData( "butlerPopup.swf", "scenes/survival4/shared/butlerPopup/" );
			butlerPopup.popupRemoved.addOnce( butlerPopupClosed );
			addChildGroup( butlerPopup );
		}
		
		private function butlerPopupClosed():void
		{
			shellApi.loadScene( GuestRoom );
		}
		
		/**
		 * 		GET INTO TROPHY ROOM
		 */
		private function trophyRoomLocked( player:Entity, doorTrophy:Entity ):void
		{
			var dialog:Dialog = player.get( Dialog );
			dialog.sayById( "need_trophy_room_key" );
		}
		
		private function unlockTrophyRoom( player:Entity, doorTrophy:Entity ):void
		{
			CharUtils.lockControls( player );
			SkinUtils.setSkinPart( player, SkinUtils.ITEM, "dd_key" );
			SkinUtils.setSkinPart( player, SkinUtils.ITEM2, "empty" );
			
			var motionThreshold:MotionThreshold = new MotionThreshold( "velocity", "==" );
			motionThreshold.axisValue = "x";
			motionThreshold.threshold = 0;
			
			motionThreshold.entered.addOnce( useTrophyRoomKey );
			player.add( motionThreshold );
			addSystem( new MotionThresholdSystem(), SystemPriorities.update );
		}

		private function useTrophyRoomKey():void
		{
			CharUtils.setDirection( player, true );
			CharUtils.setAnim( player, PourPitcher );
			var timeline:Timeline = player.get( Timeline );
			timeline.labelReached.add( openThatDoor );
		}
		
		private function openThatDoor( label:String ):void
		{
			if( label == "ending" )
			{
				var timeline:Timeline = player.get( Timeline );
				timeline.labelReached.removeAll();
				shellApi.triggerEvent( _events.TROPHY_ROOM_UNLOCKED, true );
				
				var trophyRoomDoor:Entity = getEntityById( "doorTrophy" );
				
				var audio:Audio = trophyRoomDoor.get( Audio );
				audio.playCurrentAction( RANDOM )
				
				player.remove( MotionThreshold );
				SkinUtils.setSkinPart( player, SkinUtils.ITEM, "empty" );
				SkinUtils.setSkinPart( player, SkinUtils.ITEM2, "empty" );
				
				var sceneInteraction:SceneInteraction = trophyRoomDoor.get( SceneInteraction );
				sceneInteraction.reached.remove( unlockTrophyRoom );
				sceneInteraction.reached.add( toTheTrophyRoom );
				CharUtils.lockControls( player, false, false );
			}
		}
		
		private function toTheTrophyRoom( player:Entity, doorTrophy:Entity ):void
		{
			var door:Door = doorTrophy.get( Door );
			var doorData:DoorData = door.allData[ "default" ];
			
			var audio:Audio = doorTrophy.get( Audio );
			audio.playCurrentAction( DOOR_OPEN );
			
			shellApi.loadScene( doorData );
		}
		
		private function lockedTight():void
		{
			_pulls ++;
			if( _pulls == 1 )
			{
				var dialog:Dialog = player.get( Dialog );
				var timeline:Timeline = player.get( Timeline );
				timeline.handleLabel( "loop", lockedTight );
				dialog.sayById( "must_escape" );
			}
			else 
			{
				_pulls = 0;
				CharUtils.stateDrivenOn( player );
			}
		}
		
		private function askForPassword( player:Entity, securityPanel:Entity ):void
		{
			if( !_addressingPanel )
			{
				_addressingPanel = true;
				SceneUtil.lockInput( this );
				var dialog:Dialog = securityPanel.get( Dialog );
				
				dialog.sayById( "keycode" );
				dialog.complete.addOnce( launchSecurityPopup );
			}
		}
		
		private function launchSecurityPopup( dialogData:DialogData ):void
		{
			SceneUtil.lockInput( this, false );
			var securityPanel:SecurityPopup = super.addChildGroup( new SecurityPopup( overlayContainer )) as SecurityPopup;
		
			securityPanel.complete.add( completeKeyCode );
			securityPanel.closeClicked.add( closedSecurityPopup );
		}
		
		private function completeKeyCode( popup:SecurityPopup ):void
		{
			var securityPanel:Entity = getEntityById( "securityInteraction" );
			var dialog:Dialog = securityPanel.get( Dialog );
			
			popup.close();
			
			dialog.complete.removeAll();
			dialog.sayById( "acceptedKey" );
		}
		
		private function closedSecurityPopup( popup:SecurityPopup ):void
		{
			_addressingPanel = false;
		}
		
		private function askForTallyHo( player:Entity, security:Entity ):void
		{
			var dialog:Dialog = security.get( Dialog );
			
			dialog.complete.removeAll();
			dialog.sayById( "authorization" );
		}
		
		private function tallyHoGiven( dialogData:DialogData ):void
		{
			var voiceLock:Entity = getEntityById( "voiceLockScene" );
			
			var audio:Audio = voiceLock.get( Audio );
			audio.playCurrentAction( RANDOM );
			
			var securityPanel:Entity = getEntityById( "securityInteraction" );
			var dialog:Dialog = securityPanel.get( Dialog );
			dialog.sayById( "acceptedKey" );
			
			var timeline:Timeline = voiceLock.get( Timeline );
			timeline.gotoAndStop( 1 );
			
			shellApi.triggerEvent( _events.TALLY_HO_DOWN, true );
			
			if( shellApi.checkEvent( _events.CODE_ENTERED ))
			{
				var masterLock:Entity = getEntityById( "masterLockScene" );
				timeline = masterLock.get( Timeline );
				timeline.gotoAndStop( 1 );
				
				audio = masterLock.get( Audio );
				audio.playCurrentAction( RANDOM );
				
				var door:Entity = getEntityById( "doorGrounds" );
				var sceneInteraction:SceneInteraction = door.get( SceneInteraction );
				sceneInteraction.reached.removeAll();
				sceneInteraction.reached.add( toTheGrounds );				
				
				removeEntity( getEntityById( "securityInteraction" ));
			}
		}

		private function thoughtHandler():void
		{
			var dialog:Dialog = player.get( Dialog );
					
			if( !shellApi.checkItemEvent( _events.VOICE_RECORDING ))
			{
				dialog.sayById( "no_recording" );	
			}
			else
			{
				dialog.sayById( "tally_ho" );
			}
		}
		
		/**
		 * 		DOOR LOGIC
		 */		
		// OPEN SECURITY DOOR
		private function tryTheDoor( player:Entity, door:Entity ):void
		{
			var audio:Audio = door.get( Audio );
			audio.playCurrentAction( RANDOM );
			
			CharUtils.setAnim( player, Pull );
			var timeline:Timeline = player.get( Timeline );
			timeline.handleLabel( "loop", lockedTight );
		}
		
		private function toTheGrounds( player:Entity, doorGrounds:Entity ):void
		{
			var door:Door = doorGrounds.get( Door );
			var doorData:DoorData = door.allData[ "default" ];
			
			var audio:Audio = doorGrounds.get( Audio );
			audio.playCurrentAction( DOOR_OPEN );
			
			shellApi.loadScene( Grounds, doorData.destinationSceneX, doorData.destinationSceneY, doorData.destinationSceneDirection );
		}
		
		
		// VAN BUREN INTRO
		private function wantToGoHome( player:Entity, door:Entity ):void
		{
			var dialog:Dialog = player.get( Dialog );
			var id:Id = door.get( Id );
			
			if( !shellApi.checkEvent( _events.DINNER_SEQUENCE ))
			{
				dialog.sayById( "get_on_with_it" );
			}
			else
			{
				if( id.id == "doorVanBuren" )
				{
					var winston:Entity = getEntityById( "winston" );
					dialog = winston.get( Dialog );	
					
					dialog.sayById( "dinner" );
				}
				else
				{
					dialog.sayById( "nom_noms" );
				}
			}
		}
		
	}
}