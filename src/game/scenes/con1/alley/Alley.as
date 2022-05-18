package game.scenes.con1.alley
{
	import flash.display.BitmapData;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Camera;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.creators.InteractionCreator;
	
	import fl.motion.easing.Quadratic;
	
	import game.components.animation.FSMControl;
	import game.components.animation.FSMMaster;
	import game.components.entity.AlertSound;
	import game.components.entity.Dialog;
	import game.components.entity.Sleep;
	import game.components.entity.character.CharacterMotionControl;
	import game.components.hit.Bounce;
	import game.components.hit.EntityIdList;
	import game.components.motion.Destination;
	import game.components.motion.TargetSpatial;
	import game.components.motion.Threshold;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.Timeline;
	import game.creators.entity.BitmapTimelineCreator;
	import game.creators.entity.EmitterCreator;
	import game.creators.scene.HitCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.animation.entity.character.Dizzy;
	import game.data.animation.entity.character.Guitar;
	import game.data.animation.entity.character.SledgeHammer;
	import game.data.animation.entity.character.Soar;
	import game.data.animation.entity.character.Stand;
	import game.data.animation.entity.character.Think;
	import game.data.game.GameEvent;
	import game.data.scene.characterDialog.DialogData;
	import game.data.scene.hit.HitType;
	import game.scenes.carrot.vent.VentDust;
	import game.scenes.con1.shared.Poptropicon1Scene;
	import game.systems.entity.AlertSoundSystem;
	import game.systems.entity.character.states.CharacterState;
	import game.systems.motion.FollowTargetSystem;
	import game.systems.motion.ThresholdSystem;
	import game.ui.popup.IslandEndingPopup;
	import game.ui.showItem.ShowItem;
	import game.util.BitmapUtils;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.MotionUtils;
	import game.util.PerformanceUtils;
	import game.util.PlatformUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.counters.Blast;
	import org.flintparticles.common.initializers.BitmapImage;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.RotateToDirection;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.DiscZone;

	public class Alley extends Poptropicon1Scene
	{
		private var completionsUpdated:Boolean;
		private var endingPopupWaiting:Boolean;

		public function Alley()
		{
			super();
		}
		
			// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/con1/alley/";
			
			super.init(container);
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();
		}
		
		// all assets ready
		override public function loaded():void
		{
			_bitmapQuality = ( PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_LOW ) ? .5 : 1;
			_alertSystem = new AlertSoundSystem();
			var npcs:Array = new Array( getEntityById( "guard1" ), getEntityById( "guard2" ), getEntityById( BOUNCER ));
		
			if( !shellApi.checkEvent( _events.BOUNCER_OUT ))
			{
				_alertSystem.triggered.add( getOff );
				
				getEntityById( "wood" ).add( new AlertSound());
				getEntityById( "tires" ).add( new AlertSound());
			}
			else
			{
				npcs.pop();
				_alertSystem.triggered.add( crankCatapult );
			}
			addSystem( _alertSystem );
			addSystem( new FollowTargetSystem());
			addSystem( new ThresholdSystem());
			
			super.loaded();
			var npc:Entity;
			
			for each( npc in npcs )
			{
				tweekDialogs( npc );
			}
			
			var cameraEntity:Entity = getEntityById( "camera" );
			var camera:Camera = cameraEntity.get( Camera );

			addAllDust();
			setupCatapult();
		}
		
		override public function handleEventTrigger( event:String, makeCurrent:Boolean = true, init:Boolean = false, removeEvent:String = null ):void
		{
			var bouncer:Entity;
			var dialog:Dialog;
			var camera:Camera;
			var cameraEntity:Entity;
			var cameraTarget:TargetSpatial;
			var timeline:Timeline;
			
			switch( event )
			{
				case _events.PANIC:
					var hero:Entity = getEntityById( "hero" );
					CharUtils.setDirection( hero, false );
					break;
				
				case _events.BEHOND_MJOLNIR:
					var spatial:Spatial = player.get( Spatial );
					bouncer = getEntityById( BOUNCER );
					if( bouncer )
					{
						var bouncerSpatial:Spatial = bouncer.get( Spatial );
						
						if( spatial.x > bouncerSpatial.x - 150 && spatial.x < bouncerSpatial.x + 150 && spatial.y > 1700 && !dressedLikeThor())
						{
							SceneUtil.lockInput( this, true );
							dialog = bouncer.get( Dialog );
							dialog.sayById( "showMjolnir" );
						}
					}
					break;
				
				case _events.DAT_CATAPULT:
					bouncer = getEntityById( BOUNCER );
					CharUtils.setDirection( bouncer, true );
					
					cameraEntity = super.getEntityById( "camera" );
					camera = cameraEntity.get( Camera );
					cameraTarget = cameraEntity.get( TargetSpatial );
					
					cameraTarget.target = getEntityById( "catapult" ).get( Spatial );
					camera.rate = .05;
					
					
					dialog = bouncer.get( Dialog );
					dialog.faceSpeaker = false;
					dialog.sayById( "catapult" );
					break;
				
				case _events.INQUIRE_FURTHER:
					bouncer = getEntityById( BOUNCER );
					cameraEntity = super.getEntityById( "camera" );
					cameraTarget = cameraEntity.get(TargetSpatial);
					
					cameraTarget.target = player.get( Spatial );
					
					dialog = bouncer.get( Dialog );
					dialog.faceSpeaker = true;
					
					dialog = player.get( Dialog );
					dialog.sayById( "inquireFurther" );
					break;
							
				case _events.FLASH_HAMMER:
					flashHammer();
					break;
				
				case _events.REGAIN_CONTROL:
					SceneUtil.lockInput( this, false );
					
					cameraEntity = super.getEntityById( "camera" );
					camera = cameraEntity.get( Camera );
					
					camera.rate = .2;
					regainControl();
					break;
				
				case _events.THOR_ALMIGHTY:
					bouncer = getEntityById( BOUNCER );
					CharUtils.setAnim( bouncer, Dizzy );
					timeline = bouncer.get( Timeline );
					timeline.handleLabel( "ending", isItTrue );
					break;
				
				case _events.BOUNCER_OUT:
					bouncer = getEntityById( BOUNCER );
					if( bouncer )
					{
						CharUtils.setAnim( bouncer, Guitar );
						timeline = bouncer.get( Timeline );
						timeline.handleLabel( "ending", exitSceneLeft );
					}
					break;
			}
			
			super.handleEventTrigger(event, makeCurrent, init, removeEvent);
		}
		
		private function removeBouncer( bouncer:Entity ):void
		{
			removeEntity( bouncer );
		}
		
		/**
		 * TWEEK DIALOGS
		 * 		since the guards will only respond, we need to set their dialog slightly different
		 */
		private function tweekDialogs( npc:Entity ):void
		{
			var sceneInteraction:SceneInteraction = npc.get( SceneInteraction );
			
			sceneInteraction.reached.removeAll();
			sceneInteraction.reached.add( talkToMe );
		}
		
		private function talkToMe( player:Entity, npc:Entity ):void
		{
			var dialog:Dialog = player.get( Dialog );
			var id:Id = npc.get( Id );
			
			if( id.id == BOUNCER && !dialog.speaking )
			{
				SceneUtil.lockInput( this );
				
				if( shellApi.checkEvent( GameEvent.GOT_ITEM + _events.MJOLNIR ))	
				{
					if( dressedLikeThor())
					{ 
						if( !SkinUtils.hasSkinValue( player, SkinUtils.ITEM, MJOLNIR ))
						{
							SkinUtils.setSkinPart( player, SkinUtils.ITEM, MJOLNIR );
						}
						
						dialog.sayById( "iAmWhoAm" );
					}
					
					else if( SkinUtils.hasSkinValue( player, SkinUtils.ITEM, MJOLNIR ))
					{
						flashHammer();
					}
					
					else
					{
						dialog.sayById( id.id );
					}
				}
				
				else
				{
					dialog.sayById( id.id );
				}
			}
			
			else
			{
				dialog.sayById( id.id );
			}
		}
		
		/**
		 * BOUNCER LOGIC
		 */
		private function getOff():void
		{
			var bouncer:Entity = getEntityById( BOUNCER );
			var dialog:Dialog = bouncer.get( Dialog );
			dialog.sayById( "getOff" );
			dialog.complete.add( regainControl );
			
			var bouncerSpatial:Spatial = bouncer.get( Spatial );
			
			var destination:Destination = CharUtils.moveToTarget( player, bouncerSpatial.x - 100, bouncerSpatial.y, true, faceEachOther );
			destination.ignorePlatformTarget = true;
			
			var bounce:Entity = getEntityById( "bounce" );
			bounce.remove( Bounce );
		}
		
		private function faceEachOther( player:Entity ):void
		{
			CharUtils.setDirection( player, true );
			CharUtils.setDirection( getEntityById( BOUNCER ), false );
		}
		
		private function regainControl( dialogData:DialogData = null ):void
		{
			CharUtils.lockControls( player, false, false );
			
			var bounce:Entity = getEntityById( "bounce" );
			var bounceHit:Bounce = new Bounce();
			bounceHit.velocity = new Point( 0, -1200 );
			bounce.add( bounceHit );
		}
		
		private function dressedLikeThor():Boolean
		{
			if( SkinUtils.hasSkinValue( player, SkinUtils.HAIR, THOR ) 
				&& SkinUtils.hasSkinValue( player, SkinUtils.MARKS, THOR ) 
				&& SkinUtils.hasSkinValue( player, SkinUtils.PACK, THOR ) 
				&& SkinUtils.hasSkinValue( player, SkinUtils.OVERSHIRT, THOR ))
			{
				return true;
			}
			else
			{
				return false;
			}
		}
		
		private function flashHammer():void
		{
			CharUtils.triggerSpecialAbility( player );
			
			if( dressedLikeThor())
			{
				var timeline:Timeline = player.get( Timeline );
				timeline.handleLabel( "ending", hammerFlashHandler );
			}
		}
		
		private function hammerFlashHandler():void
		{
			var bouncer:Entity = getEntityById( BOUNCER );
			if( bouncer )
			{
				CharUtils.setAnim( bouncer, Think, false, 80 );
					
				var dialog:Dialog = bouncer.get( Dialog );
				dialog.sayById( "repost" );
			}
		}
		
		private function isItTrue():void
		{
			var bouncer:Entity = getEntityById( BOUNCER );
			CharUtils.setAnim( bouncer, Stand );
			
			var dialog:Dialog = bouncer.get( Dialog );
			dialog.sayById( "cantBe" );
		}
		
		private function exitSceneLeft():void
		{
			// remove lock on catapult
			getEntityById( "wood" ).remove( AlertSound );
			getEntityById( "tires" ).remove( AlertSound );
			
			_alertSystem.triggered.removeAll();
			_alertSystem.triggered.add( crankCatapult );
			
			var bouncer:Entity = getEntityById( BOUNCER );
			CharUtils.moveToTarget( bouncer, 490, 1790, true, removeBouncer );
			SceneUtil.lockInput( this, false );
			shellApi.completeEvent( _events.BOUNCER_OUT );
		}
		/**
		 * ADD DUST TO THE VENTS
		 */
		private function addAllDust():void
		{
			var allDustData:Vector.<Object> = new Vector.<Object>();
			
			allDustData.push( { x : 2250, y : 865, bounds : new Rectangle( 2200, 570, 100, 300 )});
			allDustData.push( { x : 3290, y : 865, bounds : new Rectangle( 3240, 570, 100, 300 )});
			
			for( var number:uint = 0; number < allDustData.length; number++ )
			{
				addDust( allDustData[ number ], number );
			}
		}
		
		private function addDust( dustData:Object, number:int ):void
		{
			var dust:VentDust = new VentDust();
			var dustX:Number = dustData.bounds.x - 100;
			var dustY:Number = dustData.bounds.y - 160;
			
			dust.init( new Rectangle( dustX, dustY, dustX + 200, dustData.y + 10 ), 2, 0xff204556, 0x33316A85);
			
			var entity:Entity = EmitterCreator.create( this, super._hitContainer, dust );
			var spatial:Spatial = entity.get( Spatial );
			
			spatial.x = dustData.x;
			spatial.y = dustData.y;
			
			var sleep:Sleep = new Sleep();
			sleep.zone = dustData.bounds;
			entity.add( sleep ).add( new Id( "vent" + number ));
			
			_audioGroup.addAudioToEntity( entity );
			entity.add( new AudioRange( 500, 0, .5 ));
			
			var audio:Audio = entity.get( Audio );
			audio.playCurrentAction( RANDOM );
		}
		
		/**
		 * CATAPULT ENTITY CREATION
		 * 		create all interactive pieces and bitmap accordingly
		 */
		private function setupCatapult():void
		{
			var clip:MovieClip;
			var creator:HitCreator = new HitCreator();
			var entity:Entity;
			
			// CATAPULT FRAME
			clip = _hitContainer[ "catapult" ];
			
			entity = EntityUtils.createSpatialEntity( this, clip ); 
			entity.add( new Id( "catapult" ));
			_audioGroup.addAudioToEntity( entity );
			
			if(!PlatformUtils.isDesktop)
			{
				DisplayUtils.bitmapDisplayComponent( entity, true, _bitmapQuality );
			}
			
			// CATAPULT ARM
			clip = _hitContainer[ "tossBar" ];
			_tossBar = EntityUtils.createSpatialEntity( this, clip );
			_tossBar.add( new Id( "tossBar" )).add( new Tween());
			_audioGroup.addAudioToEntity( _tossBar );			
			
			entity = EntityUtils.createSpatialEntity( this, clip[ "arm" ]); 
			entity.add( new Id( "arm" ));
			
			if(!PlatformUtils.isDesktop)
			{
				DisplayUtils.bitmapDisplayComponent( entity, true, _bitmapQuality );
			}
			
			// CATAPULT LEVER	
			_lever = EntityUtils.createSpatialEntity( this, clip[ "lever" ]); 
			_lever.add( new Id( "lever" )).add( new Tween());
			_audioGroup.addAudioToEntity( _lever );
			
			if(!PlatformUtils.isDesktop)
			{
				DisplayUtils.bitmapDisplayComponent( entity, true, _bitmapQuality );
			}
			
			// CATAPULT NEST
			clip = _hitContainer[ "catapultNest" ];
			_catapultNest = EntityUtils.createSpatialEntity( this, clip );
			_catapultNest.add( new Id( "catapultNest" )).add( new AlertSound( true )).add( new Tween());
			
			var hitCreator:HitCreator = new HitCreator();
			hitCreator.addHitSoundsToEntity( _catapultNest, _audioGroup.audioData, shellApi );
			
			creator.makeHit( _catapultNest, HitType.PLATFORM, null, this );
			
			_barRotation = new Vector.<Number>;
			_platformOrientation = new Vector.<Object>;
			
			_barRotation.push( -12, 8, 28 );
			_platformOrientation.push( { x : 3783, y : 1500, rotation : -12 }
				, { x : 3807, y : 1583, rotation : 8 }
				, { x : 3800, y : 1675, rotation : 28 });
			
			// WINDOW
			clip = _hitContainer[ "window" ];
			var window:Entity = EntityUtils.createSpatialEntity( this, clip );
			window.add( new Id( "window" ));
			_audioGroup.addAudioToEntity( window );
			
			BitmapTimelineCreator.convertToBitmapTimeline( window, clip );
			var timeline:Timeline = window.get( Timeline );
			timeline.gotoAndStop( 0 );
			
			var number:int = 0;
			_shardEmitter = new Vector.<Emitter2D>;
			for( number = 0; number < 3; number ++ )
			{
				clip = _hitContainer[ "glass0" + number ];
				var bitmapData:BitmapData = BitmapUtils.createBitmapData( clip );
				_shardEmitter.push( createGlassShards( bitmapData ));
				var offsetX:Number = 1200 + ( Math.random() * 10 - 5 );
				var offsetY:Number = 900 + ( Math.random() * 10 - 5 );
				
				if( !PlatformUtils.isMobileOS || ( PlatformUtils.isMobileOS && number == 0 ))
				{
					var shardEmitterEntity:Entity = EmitterCreator.create( this, _hitContainer, _shardEmitter[ number ], offsetX, offsetY, null, "shardEmitter", null, false );
				}
			}
			
			var poster:Entity = getEntityById( "thorInteraction" );
			if( !shellApi.checkEvent( "viking2_quest_accepted" ))
			{
				removeEntity( poster );
			}
			else
			{
				var sceneInteraction:SceneInteraction = poster.get( SceneInteraction );
				sceneInteraction.reached.add( thorIsCool );
			}
		}
		
		private function thorIsCool( player:Entity, poster:Entity ):void
		{
			var dialog:Dialog = player.get( Dialog );
			dialog.sayById( "bucky" );
		}
	 	
		private function createGlassShards( bitmapData:BitmapData ):Emitter2D
		{
			var emitter:Emitter2D = new Emitter2D();
			emitter.counter = new Blast( 4 );

			emitter.addInitializer( new BitmapImage(bitmapData));
			emitter.addInitializer( new Lifetime( 1, 1.2 ));
			emitter.addInitializer( new Velocity( new DiscZone( new Point( 0, 0 ), 400, 10 )));
				
			emitter.addAction( new Age( ));
			emitter.addAction( new Move( ));
			emitter.addAction( new RotateToDirection());
			emitter.addAction( new Accelerate( 0, 620 ));
			
			return emitter;
		}
		
		/**
		 * CATAPULT CRANK LOGIC
		 * 		cranks one space each time the player jumps on it
		 */
		private function crankCatapult():void
		{
			if( !_locked )
			{
				var spatial:Spatial = _tossBar.get( Spatial );
				var audio:Audio =  _tossBar.get( Audio );
				var tween:Tween = _tossBar.get( Tween );
				var alert:AlertSound = _catapultNest.get( AlertSound );
				
				_locked = true;
				if( _currentRatchet < _barRotation.length && alert.active )
				{
					var rotation:Number = _barRotation[ _currentRatchet ];
					var platformPosition:Object = _platformOrientation[ _currentRatchet ];
					audio.playCurrentAction( RANDOM );
					
					_currentRatchet ++;
					tween.to( spatial, CRANK_SPEED, { rotation : rotation, ease : Quadratic.easeOut });
					
					spatial = _catapultNest.get( Spatial );
					tween = _catapultNest.get( Tween );

					tween.to( spatial, CRANK_SPEED, { rotation : platformPosition[ "rotation" ], x : platformPosition[ "x" ], y : platformPosition[ "y" ], ease : Quadratic.easeOut, onComplete : unlockCatapult });
					_alertSystem.triggered.removeAll();
				}
			}
		}
		
		private function unlockCatapult():void
		{
			_locked = false;
			
			if( _currentRatchet == _barRotation.length )
			{
				lockInPlace();
			}
			else
			{
				_alertSystem.triggered.add( crankCatapult );
			}
		}
		
		/**
		 * CATAPULT LOCKED IN PLACE 
		 * 		create interaction for final sequence
		 */
		private function lockInPlace():void
		{
			var spatial:Spatial = _lever.get( Spatial );
			var tween:Tween = _lever.get( Tween );
			var audio:Audio = _lever.get( Audio );
			
			audio.playCurrentAction( CLICK );
			
			tween.to( spatial, .25, { rotation : -18, onComplete : createLeverInteraction });
		}
		
		private function createLeverInteraction():void
		{
			var clip:MovieClip = _hitContainer[ "leverTrigger" ];
			var entity:Entity = EntityUtils.createSpatialEntity( this, clip );
			entity.add( new Id( "leverTrigger" ));
			
			InteractionCreator.addToEntity( entity, [ InteractionCreator.CLICK ]);
			ToolTipCreator.addToEntity( _lever );
			var sceneInteraction:SceneInteraction = new SceneInteraction();
			sceneInteraction.validCharStates = new <String>[ CharacterState.STAND, CharacterState.WALK ]; 
			entity.add( sceneInteraction );	
			sceneInteraction.reached.add( readyForLaunch );
			sceneInteraction.minTargetDelta.x = 30;
			sceneInteraction.offsetX = 30;
		}
		
		/**
		 * FINAL SEQUENCE
		 * 		break into that con
		 */
		private function readyForLaunch( player:Entity, trigger:Entity ):void
		{
			
			var idList:EntityIdList = getEntityById( "catapultNest" ).get( EntityIdList );
			if( idList.entities.length > 0 )
			{
				MotionUtils.zeroMotion( player );
				FSMControl( player.get( FSMControl )).setState( CharacterState.STAND );
				SceneUtil.lockInput( this );
				
				var vents:Vector.<Entity> = new Vector.<Entity>;
				var vent:Entity;
				var sleep:Sleep;
				
				vents.push( getEntityById( "vent0" ), getEntityById( "vent1" ));
				
				for each( vent in vents )
				{
					sleep = vent.get( Sleep );
					sleep.sleeping = false;
					sleep.ignoreOffscreenSleep = true;
				}
				if( !SkinUtils.hasSkinValue( player, SkinUtils.ITEM, MJOLNIR ))
				{
					SkinUtils.setSkinPart( player, SkinUtils.ITEM, MJOLNIR );
				}
				
				if( !shellApi.checkEvent( GameEvent.HAS_ITEM + _events.MEDAL_CON_1 ))
				{
					this.shellApi.completedIsland("", null);
					shellApi.getItem( _events.MEDAL_CON_1, null, true );
					var showItem:ShowItem = getGroupById( ShowItem.GROUP_ID ) as ShowItem;
					
					showItem.transitionComplete.addOnce( gotMedal );
				}
				else
				{
					gotMedal();
				}

		//		AudioUtils.stop( this, SoundManager.MUSIC_PATH + THEME );
		//		AudioUtils.play( this, SoundManager.MUSIC_PATH + FOR_GLORY, 1, true, [ SoundModifier.FADE ]);
				shellApi.triggerEvent( _events.FOR_GLORY );
			}
		}

		private function gotMedal():void
		{
			var dialog:Dialog = player.get( Dialog );
			
			dialog.sayById( "forGlory" );
			dialog.complete.addOnce( forGlory );
			
		}
		
		private function forGlory( dialogData:DialogData ):void
		{
			var cameraEntity:Entity = super.getEntityById( "camera" );
			var camera:Camera = cameraEntity.get(Camera);

			camera.minCameraScale = .45;
			camera.scaleRate = .015;
			camera.scaleTarget = .45;
		
			CharUtils.setAnim( player, SledgeHammer );
			var timeline:Timeline = player.get( Timeline );
			
			timeline.handleLabel( "trigger", hammerSmash );
		}
		
		private function hammerSmash():void
		{
			var audio:Audio = _lever.get( Audio );
			audio.playCurrentAction( RANDOM );
			
			var spatial:Spatial = _lever.get( Spatial );
			var tween:Tween = _lever.get( Tween );
			
			tween.to( spatial, .02, { rotation : - 48, onComplete : launchCatapult });
			var timeline:Timeline = player.get( Timeline );
			
			timeline.labelReached.removeAll();
		}
		
		private function launchCatapult():void
		{
			player.remove( FSMControl );
			player.remove( FSMMaster );
			player.remove( CharacterMotionControl );
			
			CharUtils.setAnim( player, Soar );
			var spatial:Spatial = _tossBar.get( Spatial );
			var tween:Tween = _tossBar.get( Tween );
			
			// double all of these except the latch
			tween.to( spatial, .6, { rotation : -56, ease : Quadratic.easeOut });
			
			tween = new Tween();
			spatial = player.get( Spatial );
			
			
			var motion:Motion = player.get( Motion );
			motion.rotationVelocity = -40;
			
			player.add( tween );
			tween.to( spatial, 4, { x : 1000 }, "xTween" );
			tween.to( spatial, 1.6, { y : 380, ease : Quadratic.easeOut, onComplete : floatForAMoment }, "yTween" );	
			
			var audio:Audio = getEntityById( "catapult" ).get( Audio );
			audio.playCurrentAction( RANDOM );
		}
		
		private function floatForAMoment():void
		{
			var threshold:Threshold = new Threshold( "rotation", "<" );
			threshold.threshold = -130;
			threshold.entered.addOnce( stopRotation );
			player.add( threshold );
			
			SceneUtil.addTimedEvent( this, new TimedEvent( .2, 1, startDescent ));
		}
		
		private function stopRotation():void
		{			
			var motion:Motion = player.get( Motion );
			motion.rotationVelocity = 0;			
		}
		
		private function startDescent():void
		{
			var tween:Tween = player.get( Tween );
			var spatial:Spatial = player.get( Spatial );
			
			tween.to( spatial, 1.6, { y : 1500, ease : Quadratic.easeIn });
			
			var threshold:Threshold = player.get( Threshold );
			threshold.property = "y";
			threshold.operator = ">";
			threshold.threshold = 870;
			threshold.entered.addOnce( breakWindow );
		}
		
		private function breakWindow():void
		{
			var window:Entity = getEntityById( "window" );
			var audio:Audio = window.get( Audio );
			audio.playCurrentAction( RANDOM );
			
			var timeline:Timeline = window.get( Timeline );
			timeline.gotoAndStop( 1 );
			
			var display:Display = player.get( Display );
			var tween:Tween = new Tween();
			tween.to(display, 0.15, {alpha:0});
			player.add(tween);
			
			var emitter:Emitter2D;
			
			for( var number:int = 0; number < _shardEmitter.length; number ++ )
			{
				emitter = _shardEmitter[ number ];
				emitter.start();
			}
			
			SceneUtil.addTimedEvent( this, new TimedEvent( 2, 1, breakingIn ));
		}
		
		private function breakingIn():void
		{
			SceneUtil.lockInput( this, false );
			addChildGroup(new IslandEndingPopup(this.overlayContainer));
		}
		
		private const BOUNCER:String 	= 				"bouncer";
	//	private const FOR_GLORY:String	=				"for_glory.mp3";
	//	private const THEME:String =					"poptropicon1_main_theme.mp3";
		private const MJOLNIR:String 	=				"poptropicon_mjolnir";
		private const THOR:String		=				"poptropicon_thor";
		private const RANDOM:String		=				"random";
		private const CLICK:String =					"click";
		
		private const CRANK_SPEED:Number =	1.1;
		private var _locked:Boolean = false;
		private var _currentRatchet:Number = 0;
		private var _alertSystem:AlertSoundSystem;
		private var _bitmapQuality:Number = 1;
		private var _catapultNest:Entity;
		private var _lever:Entity;
		private var _tossBar:Entity;
		private var _shardEmitter:Vector.<Emitter2D>;
		
		private var _barRotation:Vector.<Number>;
		private var _platformOrientation:Vector.<Object>;
	}
}