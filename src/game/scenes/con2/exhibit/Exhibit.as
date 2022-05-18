package game.scenes.con2.exhibit
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Camera;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Motion;
	import engine.components.MotionBounds;
	import engine.components.OwningGroup;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.creators.InteractionCreator;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.entity.Dialog;
	import game.components.entity.Sleep;
	import game.components.entity.character.CharacterMotionControl;
	import game.components.entity.character.Npc;
	import game.components.entity.character.Rig;
	import game.components.entity.character.Talk;
	import game.components.entity.character.animation.AnimationControl;
	import game.components.entity.character.animation.RigAnimation;
	import game.components.entity.character.part.eye.Eyes;
	import game.components.entity.character.part.item.ItemMotion;
	import game.components.entity.collider.PlatformCollider;
	import game.components.hit.CurrentHit;
	import game.components.hit.Item;
	import game.components.motion.Destination;
	import game.components.motion.FollowTarget;
	import game.components.motion.MotionThreshold;
	import game.components.motion.WaveMotion;
	import game.components.render.PlatformDepthCollision;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.Timeline;
	import game.components.ui.ToolTip;
	import game.creators.scene.HitCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.WaveMotionData;
	import game.data.animation.entity.character.Cry;
	import game.data.animation.entity.character.Focus;
	import game.data.animation.entity.character.FrontAimFire;
	import game.data.animation.entity.character.NinjaKick;
	import game.data.animation.entity.character.Proud;
	import game.data.animation.entity.character.Push;
	import game.data.animation.entity.character.Soar;
	import game.data.animation.entity.character.Stand;
	import game.data.animation.entity.character.StandNinja;
	import game.data.animation.entity.character.Stomp;
	import game.data.animation.entity.character.Think;
	import game.data.display.BitmapWrapper;
	import game.data.scene.characterDialog.DialogData;
	import game.data.scene.hit.HitType;
	import game.data.ui.ToolTipType;
	import game.scene.template.CharacterGroup;
	import game.scene.template.ItemGroup;
	import game.scenes.con2.shared.Poptropicon2Scene;
	import game.scenes.survival1.shared.components.TriggerHit;
	import game.scenes.survival1.shared.systems.TriggerHitSystem;
	import game.systems.SystemPriorities;
	import game.systems.entity.AnimationLoaderSystem;
	import game.systems.entity.character.states.CharacterState;
	import game.systems.hit.ItemHitSystem;
	import game.systems.motion.MotionThresholdSystem;
	import game.systems.motion.WaveMotionSystem;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.MotionUtils;
	import game.util.PlatformUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	
	import org.osflash.signals.Signal;
	
	public class Exhibit extends Poptropicon2Scene
	{
		private var _mannequins:Vector.<String> = new <String>[ "fashionNinja", "teenageArachnid", "muttonChops", "worldGuy", "kMan", "clear", "goldFace" ];
		private var _animations:Vector.<Class> = new <Class>[ StandNinja, NinjaKick, Stomp, Proud, Stand, Stand, Soar ];
		private var _freezeOnFrame:Vector.<uint> = new <uint>[ 0, 13, 21, 23, 1, 1, 11 ];
		private var _rotations:Vector.<Number> = new <Number>[ 0, -10, 0, 0, -30, -76, 10 ];
		private var _dollyFollowers:Vector.<String> = new <String>[ "stand1", "stand2", "dolly" ];
		private var _stands:Vector.<String> = new <String>[ "playerStand", "goldfaceStand" ];
		
		private var WORKER_1:String =	"worker1";
		private var WORKER_2:String =	"worker2";
	 	private var _animationLoader:AnimationLoaderSystem;
		private var _camera:Camera;
		private var _closeDoor:Boolean = false;
		private const TRIGGER:String = "trigger";
		
		private const SLAM:String = "machine_impact_02.mp3";
		private const ELF:String = "poptropicon_elfarcher2";
		
		private static const BOUNDARY_LEFT:Number = 1965;
		
		public function Exhibit()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/con2/exhibit/";
			
			super.init(container);
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();
		}
		
		override protected function addCharacters():void
		{
			super.addCharacters();
			
			// PRELOAD ANIMATIONS FOR SNEAKING
			var characterGroup:CharacterGroup = super.getGroupById( CharacterGroup.GROUP_ID ) as CharacterGroup;
			characterGroup.preloadAnimations( _animations, this );

			_animationLoader = super.getSystem( AnimationLoaderSystem ) as AnimationLoaderSystem;
		}
		
		// all assets ready
		override public function loaded():void
		{
			super.loaded();
			scrubAnimations();
			_camera = shellApi.camera.camera;
			
			for( var number:uint = 0; number < _mannequins.length; number ++ )
			{
				setupMannequin( number );
			}
			
			SceneUtil.addTimedEvent( this, new TimedEvent( .1, 1, freezeMannequinEyes ));
			
			var triggerHit:TriggerHit;
			var triggerPlatform:Entity;
			addSystem( new TriggerHitSystem());
			
			var clip:MovieClip;
			var wrapper:BitmapWrapper;
			var entity:Entity; 
			
			for( number = 0; number < _stands.length; number ++ )
			{
				clip = _hitContainer[ _stands[ number ]];
				wrapper = DisplayUtils.convertToBitmapSprite( clip );
				entity = EntityUtils.createSpatialEntity( this, wrapper.sprite );
				entity.add( new Id( _stands[ number ]));
				
				if( !shellApi.checkEvent( _events.EXHIBIT_OPEN ))
				{
					display = entity.get( Display );
					display.alpha = 0;
				}
			}
			
			if( !shellApi.checkEvent( _events.EXHIBIT_OPEN ))
			{
				optimizeAssets();
				var worker:Entity;
				var creator:HitCreator = new HitCreator();
				
				triggerPlatform = EntityUtils.createMovingEntity( this, _hitContainer[ "playerPlat" ]);
				triggerPlatform.add( new Id( "playerPlat" ));
				var display:Display = triggerPlatform.get( Display );
				display.alpha = 0;
				
				_audioGroup.addAudioToEntity( triggerPlatform );
				
				creator.makeHit( triggerPlatform, HitType.PLATFORM, null, this );
				triggerHit = new TriggerHit( null, new <String>[ "player" ]);
				triggerHit.triggered = new Signal();
				triggerHit.triggered.add( strikeAPose );
				triggerPlatform.add( triggerHit );
				var depth:PlatformDepthCollision = new PlatformDepthCollision();
				depth.depth = 1;
				triggerPlatform.add(depth);
				
				InteractionCreator.addToEntity( triggerPlatform, [ InteractionCreator.CLICK ]);
				ToolTipCreator.addToEntity( triggerPlatform );
				var sceneInteraction:SceneInteraction = new SceneInteraction();
				sceneInteraction.reached.add( onThePedastal );
				sceneInteraction.offsetY = -80;
				triggerPlatform.add( sceneInteraction );
				
				// THE WORKERS ARE LAZY; WE DON'T WANT THEM RUNNING ANYWHERE
				for( number = 1; number < 3; number ++ )
				{
					worker = getEntityById( "worker" + number );
					var motionControl:CharacterMotionControl = new CharacterMotionControl();
					motionControl.maxVelocityX = 150;
					worker.add( motionControl );
				}
				
				if( !shellApi.checkEvent( _events.ARCHER_COSPLAY_STARTED ))
				{
					worker = getEntityById( WORKER_1 );
					CharUtils.setAnim( worker, Think, false );
					
					SceneUtil.lockInput( this );
					CharUtils.moveToTarget( player, 2550, 940, true, letsPlayDressup );
				}
				else
				{
					Sleep( getEntityById( WORKER_1 ).get( Sleep )).sleeping = true;
					Display( getEntityById( WORKER_1 ).get( Display )).visible = false;
					Sleep( getEntityById( WORKER_2 ).get( Sleep )).sleeping = true;
					Display( getEntityById( WORKER_2 ).get( Display )).visible = false;
					Display( getEntityById( "unblock" ).get( Display )).visible = false;
					adjustSceneLimits();
				}
			}
			
			else
			{
				_dollyFollowers.push( "block", "playerPlat" );
				for( number = 0; number < _dollyFollowers.length; number ++ )
				{
					_hitContainer.removeChild( _hitContainer[ _dollyFollowers[ number ]]);
				}
				
				clip = _hitContainer[ "unblock" ];
				wrapper = DisplayUtils.convertToBitmapSprite( clip );
				entity = EntityUtils.createSpatialEntity( this, wrapper.sprite );
				entity.add( new Id( "unblock" ));
			}
			
			if( !shellApi.checkEvent( _events.OMEGON_MASK_PHOTO ))
			{
				triggerPlatform = getEntityById( "floor" );
				triggerHit = new TriggerHit( null, new <String>[ "player" ]);
				triggerHit.triggered = new Signal();
				triggerHit.triggered.addOnce( approachMask );
				triggerPlatform.add( triggerHit );
			}
			
			if( !checkHasCard( _events.FASHION_NINJA ))
			{
				clip = _hitContainer[ "card" ];
				wrapper = DisplayUtils.convertToBitmapSprite( clip );
				var card:Entity = EntityUtils.createSpatialEntity( this, wrapper.sprite );
				var interaction:Interaction;
				
				card.add( new Id( "card" ));
				
				interaction = InteractionCreator.addToEntity( card, [ InteractionCreator.CLICK ]);
				ToolTipCreator.addToEntity( card );
				
				if( !shellApi.checkEvent( _events.FASHION_NINJA_FELL ))
				{
					triggerPlatform = getEntityById( "balloonArm" );
					triggerHit = new TriggerHit( null, new <String>[ "player" ]);
					triggerHit.triggered = new Signal();
					triggerHit.triggered.add( dropCard );
					triggerPlatform.add( triggerHit );
					
					interaction.click.add( spotDatCard );
						
					addSystem( new WaveMotionSystem());
					addSystem( new MotionThresholdSystem());
				}
				else
				{
					var spatial:Spatial = card.get( Spatial );
					spatial.y = 940;
					
					addFinalCardInteraction( card );
				}
			}
			else
			{
				_hitContainer.removeChild( _hitContainer[ "card" ]);
			}
		}
		
		// BITMAP ASSETS
		private function optimizeAssets():void
		{
			// DOOR BLOCKING PATH
			var clip:MovieClip = _hitContainer[ "unblock" ];
			var wrapper:BitmapWrapper = DisplayUtils.convertToBitmapSprite( clip );
			var entity:Entity = EntityUtils.createSpatialEntity( this, wrapper.sprite );
			entity.add( new Id( "unblock" ));
			
			clip = _hitContainer[ "block" ];
			wrapper = DisplayUtils.convertToBitmapSprite( clip );
			entity = EntityUtils.createSpatialEntity( this, wrapper.sprite );
			entity.add( new Id( "block" ));
			_audioGroup.addAudioToEntity( entity );
			
			
			InteractionCreator.addToEntity( entity, [ InteractionCreator.CLICK ]);
			var sceneInteraction:SceneInteraction = new SceneInteraction();
			sceneInteraction.reached.add( doorsLocked );
			entity.add( sceneInteraction );
			ToolTipCreator.addToEntity( entity, ToolTipType.EXIT_LEFT, "GO LEFT", new Point(60, 0));
			
			// STANDS
			for( var number:uint = 0; number < _dollyFollowers.length; number ++ )
			{
				clip = _hitContainer[ _dollyFollowers[ number ]];
				wrapper = DisplayUtils.convertToBitmapSprite( clip );
				
				entity = EntityUtils.createSpatialEntity( this, wrapper.sprite );
				entity.add( new Id( _dollyFollowers[ number ]));
			}
			
			_audioGroup.addAudioToEntity( getEntityById( "dolly" ));
			getEntityById( "dolly" ).add( new AudioRange( 500, 0, 1 ));
		}
		
		private function spotDatCard( card:Entity ):void
		{
			var dialog:Dialog = player.get( Dialog );
			dialog.sayById( "dat_card" );
		}
		
		private function dropCard():void
		{
			var card:Entity = getEntityById( "card" );
			var motion:Motion = new Motion();
			motion.velocity.y = 100;
			
			var triggerPlatform:Entity = getEntityById( "balloonArm" );
			triggerPlatform.remove( TriggerHit );
			
			card.add( motion ).add( new Item());
			var waveMotion:WaveMotion = new WaveMotion();
			waveMotion.add( new WaveMotionData( "x", 3, .25 ));
			card.add( waveMotion );
			var motionBounds:MotionBounds = new MotionBounds( super.sceneData.bounds );
	
			card.add( new PlatformCollider()).add( motionBounds ).add( new CurrentHit());
			var motionThreshold:MotionThreshold = new MotionThreshold( "velocity", "==" );
			motionThreshold.axisValue = "y";
			motionThreshold.threshold = 0;
			motionThreshold.entered.addOnce( changeCardInteraction );
			card.add( motionThreshold );
			
			var interaction:Interaction = card.get( Interaction );
			interaction.click.removeAll();
		}
		
		private function changeCardInteraction():void
		{
			shellApi.completeEvent( _events.FASHION_NINJA_FELL );
			var card:Entity = getEntityById( "card" );
			card.remove( WaveMotion );
			card.remove( MotionThreshold );
			
			addFinalCardInteraction( card );
		}
		
		private function addFinalCardInteraction( card:Entity ):void
		{			
			var sceneInteraction:SceneInteraction = new SceneInteraction();
			sceneInteraction.reached.addOnce( getFashionNinja );
		
			card.add( sceneInteraction );
			card.add( new OwningGroup( this ));
			var itemGroup:ItemGroup = super.getGroupById( ItemGroup.GROUP_ID ) as ItemGroup;
			
			if( !super.getSystem( ItemHitSystem ))	// items require ItemHitSystem, add system if not yet added
			{
				var itemHitSystem:ItemHitSystem = new ItemHitSystem();
				super.addSystem( itemHitSystem, SystemPriorities.resolveCollisions );
				itemHitSystem.gotItem.add( getFashionNinja );
			}
		}
		
		private function getFashionNinja( ...args ):void
		{
			var card:Entity = getEntityById( "card" );
			addCardToDeck( _events.FASHION_NINJA );
			
			if( args.length > 1 )
			{
				removeEntity( card );
			}
		}
		
		// EVENT HANDLER
		override public function onEventTriggered( event:String, save:Boolean = true, init:Boolean = false, removeEvent:String = null ):void
		{
			var worker:Entity;
			
			switch( event )
			{
				case "sigh":
					worker = getEntityById( WORKER_1 );
					CharUtils.setAnim( worker, Cry );
					var dialog:Dialog = worker.get( Dialog );
					
					dialog.sayById( "dentists_convention" );
					break;
				
				case "off_to_work":
					letsGetOnWithIt();
					break;
			}
			
			super.onEventTriggered(event, save, init, removeEvent);
		}
		
		// SCRUB MANNEQUIN ANIMATION'S FRAME EVENTS
		private function scrubAnimations():void
		{
			var animation:*;
			
			for( var number:uint = 0; number < _animations.length; number ++ )
			{
				animation = _animationLoader.animationLibrary.getAnimation( _animations[ number ]) as _animations[ number ];
				for( var frame:uint = 0; frame < animation.data.frames.length; frame ++ )
				{
					while( animation.data.frames[ frame ].events.length > 0 )
					{
						animation.data.frames[ frame ].events.pop();
					}
				}
			}
		}
		
		private function setupMannequin( mannequinNumber:uint ):void
		{
			var mannequin:Entity = getEntityById( _mannequins[ mannequinNumber ]);
			var container:DisplayObjectContainer = _hitContainer[ "mannequinContainer" ];
			var spatial:Spatial = mannequin.get( Spatial );
			
			if( mannequinNumber == _mannequins.length - 1 )
			{
				if( !shellApi.checkEvent( _events.EXHIBIT_OPEN ))
				{
					spatial.x = 2412;		
					spatial.y = 827;
					container = _hitContainer[ "onDollyContainer" ];
				}
			}
			
			if( mannequinNumber == 3 )
			{
				var handEntity:Entity = CharUtils.getPart( mannequin, CharUtils.HAND_FRONT );
				if( handEntity )
				{
					var itemMotion:ItemMotion = new ItemMotion();
					itemMotion.isFront = true;
					handEntity.add( itemMotion );
					SkinUtils.setSkinPart( mannequin, CharUtils.HAND_FRONT, "poptropicon_saworldguy" );
				}
			}
			
			spatial.rotation = _rotations[ mannequinNumber ];
			CharUtils.setAnim( mannequin, _animations[ mannequinNumber ]);
			
			var timeline:Timeline = mannequin.get( Timeline );
			timeline.gotoAndStop( _freezeOnFrame[ mannequinNumber ]);

			var eyes:Eyes = SkinUtils.getSkinPartEntity( mannequin, SkinUtils.EYES ).get( Eyes );
			SkinUtils.setEyeStates( mannequin, eyes.state, "front", true );
			eyes.locked = true;
			
			var sleep:Sleep = mannequin.get( Sleep );
			sleep.ignoreOffscreenSleep = true;
			
			var display:Display = mannequin.get( Display );
			display.setContainer( container );
			
			mannequin.remove( AnimationControl );
			mannequin.remove( Talk );
			mannequin.remove( Dialog );
			mannequin.remove( SceneInteraction );			
			mannequin.remove( Interaction );
			mannequin.remove( RigAnimation );
			mannequin.remove( Rig );
			mannequin.remove( Npc );
			
			ToolTipCreator.removeFromEntity( mannequin );
		}
		
		private function freezeMannequinEyes():void
		{
			var entity:Entity;
			var number:uint;
			var eyes:Entity; 
			
			for( number = 0; number < _mannequins.length; number ++ )
			{
				entity = getEntityById( _mannequins[ number ]);
				
				eyes = SkinUtils.getSkinPartEntity( entity, SkinUtils.EYES );
				eyes.remove( Eyes );
			}
		}
		
		// COSPLAY PUZZLE
		private function doorsLocked( approachingEntity:Entity, interationEntity:Entity ):void
		{
			SceneUtil.lockInput( this );
			Display( getEntityById( "unblock" ).get( Display )).visible = false;
			
			super.sceneData.bounds.left = 0;
			_camera.resize( _camera.viewport.width, _camera.viewport.height, _camera.area.width + BOUNDARY_LEFT, _camera.area.height, 0 );
			
			
			SceneUtil.setCameraTarget( this, getEntityById( "worldGuy" ), false, .05 );
			SceneUtil.addTimedEvent( this, new TimedEvent( 2, 1, panBack ));
		}
		
		private function panBack():void
		{
			SceneUtil.setCameraTarget( this, getEntityById( "goldFace" ), false, .05 );
			SceneUtil.addTimedEvent( this, new TimedEvent( 1, 1, howToUnlock ));
		}
		
		private function howToUnlock():void
		{			
			super.sceneData.bounds.left = BOUNDARY_LEFT + 50;
			_camera.resize( _camera.viewport.width, _camera.viewport.height, _camera.area.width - BOUNDARY_LEFT, _camera.area.height, BOUNDARY_LEFT );

			var dialog:Dialog = player.get( Dialog );
			dialog.sayById( "locked" );
			dialog.complete.addOnce( plotToGetIn );
			
			var spatial:Spatial = player.get( Spatial );
			CharacterMotionControl( player.get( CharacterMotionControl )).maxVelocityX = 120;
			CharUtils.moveToTarget( player, spatial.x + 200, spatial.y, true );
		}
		
		private function plotToGetIn( dialogData:DialogData ):void
		{
			CharacterMotionControl( player.get( CharacterMotionControl )).maxVelocityX = 800;
			
			SceneUtil.setCameraTarget( this, player );
			SceneUtil.lockInput( this, false );
		}
		
		private function letsPlayDressup( entity:Entity ):void
		{
			var worker:Entity = getEntityById( WORKER_1 );
			SceneUtil.setCameraTarget( this, getEntityById( _dollyFollowers[ 1 ]));
			
			var dialog:Dialog = worker.get( Dialog );
			dialog.sayById( "missing_archer" );
			dialog.complete.addOnce( missingArcher );
			
			var door:Entity = getEntityById( "block" );
			Display( door.get( Display )).visible = false;
			
			door = getEntityById( "unblock" );
			Display( door.get( Display )).visible = true;
		}
		
		private function missingArcher( dialogData:DialogData ):void
		{			
			var worker:Entity = getEntityById( WORKER_1 );
			CharUtils.setAnim( worker, Stand );
			var eyes:Eyes = SkinUtils.getSkinPartEntity( worker, "eyes" ).get( Eyes );
			SkinUtils.setEyeStates( worker, "casual", null, true );
			
			worker = getEntityById( WORKER_2 );
			CharUtils.setAnim( worker, Focus );
			SkinUtils.setEyeStates( worker, "closed" );
			var timeline:Timeline = worker.get( Timeline );
			timeline.handleLabel( "ending", silverAgeArcher );
		}
		
		private function silverAgeArcher():void
		{
			var worker:Entity = getEntityById( WORKER_2 );
			SkinUtils.setEyeStates( worker, "casual", null, true );
			var dialog:Dialog = worker.get( Dialog );
			dialog.faceSpeaker = false;
			
			dialog.sayById( "silver_age_archer" );
		}
		
		private function letsGetOnWithIt():void
		{
			var worker:Entity;
			var handler:Function;
			
			for( var number:uint = 1; number < 3; number ++ )
			{
				handler = null;
				worker = getEntityById( "worker" + number );
				
				if( number == 1 )	
				{
					handler = sleepWorkers;
				}
				CharUtils.moveToTarget( worker, 1850 - ( 80 * number ), 940, true, handler );
			}
		}
		
		private function sleepWorkers( entity:Entity ):void
		{
			var worker:Entity;
			
			if( !shellApi.checkEvent( _events.ARCHER_COSPLAY_STARTED ))
			{
				shellApi.triggerEvent( _events.ARCHER_COSPLAY_STARTED, true );
				_closeDoor = true;
			}
			
			for( var number:uint = 1; number < 3; number ++ )
			{
				worker = getEntityById( "worker" + number );
				Sleep( worker.get( Sleep )).sleeping = true;
				Display( worker.get( Display )).visible = false;
			}
			
			SceneUtil.lockInput( this, false );			
			SceneUtil.addTimedEvent( this, new TimedEvent( 1, 1, adjustSceneLimits ));
		}
		
		private function adjustSceneLimits( doorLocked:Boolean = true ):void
		{	
			SceneUtil.setCameraTarget( this, player );
			if( doorLocked )
			{
				super.sceneData.bounds.left = BOUNDARY_LEFT + 50;
				_camera.resize( _camera.viewport.width, _camera.viewport.height, _camera.area.width - BOUNDARY_LEFT, _camera.area.height, BOUNDARY_LEFT );
			}
			else
			{
				super.sceneData.bounds.left = 0;
				_camera.resize( _camera.viewport.width, _camera.viewport.height, _camera.area.width + BOUNDARY_LEFT, _camera.area.height, 0 );
			}
			
			
			if( _closeDoor )
			{
				_closeDoor = false;
				var door:Entity = getEntityById( "block" );
				Display( door.get( Display )).visible = true;
				Audio( door.get( Audio )).playCurrentAction( TRIGGER );
				
				door = getEntityById( "unblock" );
				Display( door.get( Display )).visible = false;
				
				SceneUtil.lockInput( this, false );
				CharUtils.setState( player, CharacterState.STAND );
			}
		}
		
		// CHECK TO SEE IF COSTUME IS CORRECT
		private function onThePedastal( approachingEntity:Entity, interactedEntity:Entity ):void
		{
			var spatial:Spatial = player.get( Spatial );
			spatial.x = Spatial( interactedEntity.get( Spatial )).x;
		}
		
		private function strikeAPose():void
		{
			Motion(player.get(Motion)).rotation = 0;
			Motion(player.get(Motion)).rotationVelocity = 0;
			
			var triggerPlatform:Entity = getEntityById( "playerPlat" );
			var spatial:Spatial = player.get( Spatial );
			var platformSpatial:Spatial = triggerPlatform.get( Spatial );
			var audio:Audio = triggerPlatform.get( Audio );
			audio.playCurrentAction( TRIGGER );
			
			spatial.x = platformSpatial.x;
			SceneUtil.lockInput( this );
			SceneUtil.zeroRotation( player );
			MotionUtils.zeroMotion( player );
			
			CharUtils.setDirection( player, false );
			CharUtils.setAnim( player, FrontAimFire );
			var timeline:Timeline = player.get( Timeline );
			timeline.handleLabel( "frontAimStop", summonWorkers );
		}
		
		// SUMMON WORKERS AND HANDLE TRANSITION IF CORRECT COSTUME
		private function summonWorkers():void
		{
			var door:Entity = getEntityById( "block" );
			Display( door.get( Display )).visible = false;
			Audio( door.get( Audio )).playCurrentAction( TRIGGER );
			
			door = getEntityById( "unblock" );
			Display( door.get( Display )).visible = true;
			
			var multiplier:uint;
			
			var timeline:Timeline = player.get( Timeline );
			timeline.stop();
			
			adjustSceneLimits( false );
			var worker:Entity;
			var handler:Function;
			
			for( var number:uint = 1; number < 3; number ++ )
			{
				multiplier = 340;
				handler = areWeDoneYet;
				
				worker = getEntityById( "worker" + number );
				Sleep( worker.get( Sleep )).sleeping = false;
				Display( worker.get( Display )).visible = true;
				DisplayUtils.moveToTop(worker.get(Display).displayObject);
				
				if( number == 2 )
				{
					handler = null;
					multiplier = 0;
				}
				
				CharUtils.moveToTarget( worker, 2180 + ( number * multiplier ), 940, true, handler );
			}
		}
		
		private function areWeDoneYet( entity:Entity ):void
		{
			var worker:Entity;
			var dialog:Dialog;
			var spatial:Spatial;
			_closeDoor = true;
			
			if( checkCostume())
			{
				for( var number:uint = 1; number < 3; number ++ )
				{
					worker = getEntityById( "worker" + number );
					dialog = worker.get( Dialog );
					dialog.sayById( "found_it" );
					DisplayUtils.moveToTop(worker.get(Display).displayObject);
					
					if( number == 1 )
					{
						CharUtils.setDirection( worker, false );
						dialog.complete.addOnce( shrugs );
					}
					else
					{
						removeEntity( getEntityById( "block" ));
						Display( getEntityById( "unblock" ).get( Display )).visible = true;
					}
				}
			}
			else
			{
				worker = getEntityById( WORKER_1 );
				dialog = worker.get( Dialog );
				dialog.sayById( "wrong_costume" );
			}
		}
		
		private function checkCostume():Boolean
		{
			if( SkinUtils.hasSkinValue( player, SkinUtils.HAIR, ELF )
				&& SkinUtils.hasSkinValue( player, SkinUtils.MARKS, ELF )
				&& SkinUtils.hasSkinValue( player, SkinUtils.PACK, ELF )
				&& SkinUtils.hasSkinValue( player, SkinUtils.OVERSHIRT, ELF ))
			{
				return true;
			}
			else
			{
				return false;
			}
		}
		
		private function shrugs( dialogData:DialogData ):void
		{
			var worker:Entity = getEntityById( WORKER_1 );
			var dialog:Dialog = worker.get( Dialog );
			
			dialog.sayById( "unload" );
			dialog.complete.addOnce( startPushingToGoldFace );
		}
		
		private function startPushingToGoldFace( dialogData:DialogData ):void
		{
			var entity:Entity;
			var worker:Entity = getEntityById( WORKER_1 );
			
			CharUtils.setAnim( worker, Push );
			
			var tween:Tween = new Tween();
			var spatial:Spatial = worker.get( Spatial );
			tween.to( spatial, 10, { x : 1754, onComplete : moveToMannequin, onCompleteParams : [ getEntityById( "goldFace" ), startPushingToArcher ]});
			var audio:Audio = getEntityById( "dolly" ).get( Audio );
			audio.playCurrentAction( TRIGGER );
			
			worker.add( tween );
			_dollyFollowers.push( "player", "goldFace" );
			for( var number:uint = 0; number < _dollyFollowers.length; number ++ )
			{
				entity = getEntityById( _dollyFollowers[ number ]);
				addFollow( entity, spatial );
			}
			
			worker = getEntityById( WORKER_2 );
			spatial = worker.get( Spatial );
			CharUtils.moveToTarget( worker, 1580, spatial.y, true );
		}
	
		private function startPushingToArcher():void
		{
			var goldFace:Entity = getEntityById( _dollyFollowers.pop());
			Display( goldFace.get( Display )).setContainer( _hitContainer[ "mannequinContainer" ]);
			Spatial( goldFace.get( Spatial )).y = 837;
			AudioUtils.play( this, SoundManager.EFFECTS_PATH + SLAM );
			
			Display( getEntityById( _stands.pop()).get( Display )).alpha = 1;
			Display( getEntityById( "stand2" ).get( Display )).alpha = 0;
			
			goldFace.remove( FollowTarget );
			var audio:Audio = getEntityById( "dolly" ).get( Audio );
			audio.playCurrentAction( TRIGGER );
			
			var worker:Entity = getEntityById( WORKER_1 );
			CharUtils.setAnim( worker, Push );
			
			var tween:Tween = worker.get( Tween );
			var spatial:Spatial = worker.get( Spatial );
			tween.to( spatial, 5, { x : 1450, onComplete : moveToMannequin, onCompleteParams : [ getEntityById( "player" ), workersExit ]});
			
			worker = getEntityById( WORKER_2 );
			spatial = worker.get( Spatial );
			CharUtils.moveToTarget( worker, 1400, spatial.y );
		}
		
		private function workersExit():void
		{
			Display( player.get( Display )).setContainer( _hitContainer[ "mannequinContainer" ]);
			var spatial:Spatial = player.get( Spatial );
			spatial.y = 854;
			AudioUtils.play( this, SoundManager.EFFECTS_PATH + SLAM );
			
			Display( getEntityById( _stands.pop()).get( Display )).alpha = 1;
			Display( getEntityById( "stand1" ).get( Display )).alpha = 0;
			
			var entity:Entity;
			var followTarget:FollowTarget;
			player.remove( FollowTarget );
			_dollyFollowers.pop();
				
			for( var number:int = 0; number < _dollyFollowers.length; number ++ )
			{
				entity = getEntityById( _dollyFollowers[ number ]);
				spatial = entity.get( Spatial );
				spatial.scaleX *= -1;
				
				followTarget = entity.get( FollowTarget );
				followTarget.offset.x *= -1;
			}
			var audio:Audio = getEntityById( "dolly" ).get( Audio );
			audio.playCurrentAction( TRIGGER );
			
			var worker:Entity = getEntityById( WORKER_1 );
			CharUtils.setDirection( worker, true );
			CharUtils.setAnim( worker, Push );
			
			var tween:Tween = worker.get( Tween );
			spatial = worker.get( Spatial );
			
			tween.to( spatial, 8, { x : 1900, onComplete : removeWorkers });
			
			worker = getEntityById( WORKER_2 );
			spatial = worker.get( Spatial );
			CharUtils.moveToTarget( worker, 1900, spatial.y ); 
			
			removeEntity( getEntityById( "playerPlat" ));
		}
		
		private function removeWorkers():void
		{
			Display( player.get( Display )).setContainer( _hitContainer );
			var dialog:Dialog = player.get( Dialog );
			
			var removals:Vector.<String> = new <String>[ WORKER_1, WORKER_2, "stand1", "stand2", "dolly" ];
			
			for( var number:uint = 0; number < removals.length; number ++ )
			{
				removeEntity( getEntityById( removals[ number ]));
			}
			
			dialog.sayById( "so_sneaky" );
			dialog.complete.addOnce( cosplayOver );
		}
		
		private function cosplayOver( dialogData:DialogData ):void
		{
			var timeline:Timeline = player.get( Timeline );
			timeline.play();
			
			CharUtils.stateDrivenOn( player );
			SceneUtil.lockInput( this, false );
			shellApi.completeEvent( _events.EXHIBIT_OPEN )
		}
		
		// UTILITY FUNCTIONS FOR UNLOADING GOLDFACE AND ARCHER
		private function addFollow( follower:Entity, targetSpatial:Spatial ):void
		{
			var followTarget:FollowTarget = new FollowTarget( targetSpatial );
			var followerSpatial:Spatial = follower.get( Spatial );
			followTarget.offset = new Point( followerSpatial.x - targetSpatial.x, followerSpatial.y - targetSpatial.y );
			follower.add( followTarget );
		}
		
		private function moveToMannequin( mannequin:Entity, handler:Function ):void
		{
			var worker:Entity = getEntityById( WORKER_1 );
			CharUtils.setAnim( worker, Cry );
			var audio:Audio = getEntityById( "dolly" ).get( Audio );
			audio.stopActionAudio( TRIGGER );
			
			worker = getEntityById( WORKER_2 );
			var spatial:Spatial = mannequin.get( Spatial );
			
			CharUtils.moveToTarget( worker, spatial.x - 10, spatial.y, true, Command.create( unloadMannequin, handler ));
		}
		
		private function unloadMannequin( worker:Entity, handler:Function ):void
		{
			CharUtils.setDirection( worker, true );
			CharUtils.setAnim( worker, Push );
			var timeline:Timeline = worker.get( Timeline );
			timeline.handleLabel( "ending", handler );
		}
		
		// APPROACH THE MASK TO SNAP A PHOTO
		private function approachMask():void
		{
			SceneUtil.lockInput( this );
			var motionControl:CharacterMotionControl = player.get( CharacterMotionControl );
			motionControl.maxVelocityX = 120;
						
			var destination:Destination = CharUtils.moveToTarget( player, 420, Spatial( player.get( Spatial )).y, true, foundTheMask );
			destination.ignorePlatformTarget = true;
		}
		
		private function foundTheMask( entity:Entity ):void
		{
			var dialog:Dialog = player.get( Dialog );
			dialog.sayById( "sick_mask_bro" );
			CharUtils.setDirection( player, false );
			
			snapPhoto( _events.OMEGON_MASK_PHOTO, regainControl );
		}

		private function regainControl():void
		{
			var motionControl:CharacterMotionControl = player.get( CharacterMotionControl );
			motionControl.maxVelocityX = 800;
			
			var floor:Entity = getEntityById( "floor" );
			floor.remove( TriggerHit );
		}
	}
}