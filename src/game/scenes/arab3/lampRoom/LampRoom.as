package game.scenes.arab3.lampRoom
{
	import flash.display.BitmapData;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.components.SpatialAddition;
	import engine.components.Tween;
	import engine.creators.CameraLayerCreator;
	import engine.creators.InteractionCreator;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.entity.Dialog;
	import game.components.entity.Sleep;
	import game.components.entity.character.CharacterMotionControl;
	import game.components.hit.ValidHit;
	import game.components.motion.Destination;
	import game.components.motion.MotionThreshold;
	import game.components.motion.WaveMotion;
	import game.components.timeline.BitmapSequence;
	import game.components.timeline.Timeline;
	import game.creators.entity.BitmapTimelineCreator;
	import game.creators.entity.EmitterCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.WaveMotionData;
	import game.data.animation.entity.character.Cry;
	import game.data.animation.entity.character.Dizzy;
	import game.data.animation.entity.character.Grief;
	import game.data.animation.entity.character.Laugh;
	import game.data.animation.entity.character.Proud;
	import game.data.animation.entity.character.SkidNinja;
	import game.data.animation.entity.character.Stand;
	import game.data.animation.entity.character.StandNinja;
	import game.data.animation.entity.character.Sword;
	import game.data.animation.entity.character.Tremble;
	import game.data.character.LookData;
	import game.data.scene.characterDialog.DialogData;
	import game.data.specialAbility.SpecialAbilityData;
	import game.data.specialAbility.islands.arab.MagicCarpet;
	import game.scene.template.CharacterGroup;
	import game.scenes.arab3.Arab3Scene;
	import game.scenes.arab3.skyChase.SkyChase;
	import game.scenes.survival1.shared.components.TriggerHit;
	import game.scenes.survival1.shared.systems.TriggerHitSystem;
	import game.systems.entity.EyeSystem;
	import game.systems.entity.character.states.CharacterState;
	import game.systems.motion.MotionThresholdSystem;
	import game.systems.motion.ThresholdSystem;
	import game.systems.motion.WaveMotionSystem;
	import game.util.AudioUtils;
	import game.util.BitmapUtils;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.MotionUtils;
	import game.util.PerformanceUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TimelineUtils;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.counters.Blast;
	import org.flintparticles.common.initializers.BitmapImage;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.RotateToDirection;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.EllipseZone;
	import org.osflash.signals.Signal;
	
	public class LampRoom extends Arab3Scene
	{
		private const LAMP:String 			= "an3_lamp1";
		private const HUMAN_JINN:String 	= "an_genie3";
		private const JINN_THIEF:String 	= "an_genie2";
		
		private var readyToEscape:Boolean = false;
		private var _jinn:Entity;
		private var _sultan:Entity;
		private var _thief:Entity;
		
		private var _window:Entity;
		private var _characterGroup:CharacterGroup;
		
		public function LampRoom()
		{
			super();
		}
		
		override protected function addBaseSystems():void
		{
			super.addBaseSystems();
			addSystem( new ThresholdSystem());
			addSystem( new MotionThresholdSystem());	
			addSystem( new TriggerHitSystem());
		}
		
		override public function init(container:DisplayObjectContainer=null):void
		{
			super.groupPrefix = "scenes/arab3/lampRoom/";
			super.init( container );
			_numSpellTargets = 2; 
			_numThiefSpellTargets = 2; 
		}
		
		override public function smokeReady():void
		{
			super.smokeReady();
			
			player.add( new ValidHit( "pedestal", "dias_top", "carpet", "wall" ));
			_characterGroup = getGroupById( CharacterGroup.GROUP_ID ) as CharacterGroup;
			
			setupAssets();
			if( shellApi.checkEvent( _events.GENIE_IN_LAMP_ROOM ) && !shellApi.checkEvent( _events.THIEF_TRANSFORMED ))
			{
				setupCharacters();
				var cameraLayerCreator:CameraLayerCreator = new CameraLayerCreator();
				
				var lightLayerDisplay:Sprite = new Sprite();
				lightLayerDisplay.name = 'lightLayer';
				
				super.addEntity( cameraLayerCreator.create( lightLayerDisplay, 0, "lightLayer" ));
				super.groupContainer.addChild( lightLayerDisplay );
				lightLayerDisplay.mouseChildren = false;
				lightLayerDisplay.mouseEnabled = false;
			}			
			else
			{
				removeEntity( getEntityById( "thief" ));
				removeEntity( getEntityById( "jinn" ));
				removeEntity( getEntityById( "sultan" ));
			}
		}
		
		// FIGURE OUT THE WINDOW AND THE ROC FEATHER
		private function setupAssets():void
		{
			var timeline:Timeline;
			
			// MOVE ROC FEATHER BEHIND VASE
			if( !shellApi.checkItemEvent( _events.ROC_FEATHER ))
			{
				var feather:Entity 						=	getEntityById( _events.ROC_FEATHER );
				DisplayUtils.moveToOverUnder( Display( feather.get( Display )).displayObject, _hitContainer[ "vase" ], false );
				
				var waveMotion:WaveMotion = new WaveMotion();
				var waveMotionData:WaveMotionData 		= 	new WaveMotionData( "rotation", .05, .01 );
				waveMotion.add( waveMotionData );
				
				var spatial:Spatial 					=	feather.get( Spatial );
				
				feather.add( waveMotion );
				ToolTipCreator.removeFromEntity( feather );
				ToolTipCreator.addToEntity( feather, InteractionCreator.CLICK, null );
				
				addSystem( new WaveMotionSystem());
			}
			
			// FIGURE OUT WINDOW STATE
			_window = makeEntity( _hitContainer[ "window" ], true );
			timeline = _window.get( Timeline );

			if( shellApi.checkEvent( _events.THIEF_TRANSFORMED ))
			{
				timeline.gotoAndStop( 1 );
			}
			
			makeEntity( _hitContainer[ "dias" ]);
			var entity:Entity = makeEntity( _hitContainer[ "lamp" ]);
			Display( entity.get( Display )).visible = false;
		}
		
		private function makeEntity( clip:MovieClip, isTimeline:Boolean = false ):Entity
		{
			var entity:Entity;
			var sequence:BitmapSequence;
			
			if( isTimeline )
			{
				entity = EntityUtils.createSpatialEntity( this, clip );
				
				if( PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_MEDIUM )
				{
					sequence = BitmapTimelineCreator.createSequence( clip, true, PerformanceUtils.defaultBitmapQuality );
					BitmapTimelineCreator.convertToBitmapTimeline( entity, clip, true, sequence, PerformanceUtils.defaultBitmapQuality );
				}
				else
				{
					TimelineUtils.convertClip( clip, this, entity );
				}
			}
			else
			{
				BitmapUtils.convertContainer( clip );
				clip.mouseChildren = false;
				clip.mouseEnabled = false;
				
				entity = EntityUtils.createSpatialEntity( this, clip );
			}
			
			entity.add( new Id( clip.name ));
			
			return entity; 
		}
		
		private function setupCharacters():void
		{
			_thief = getEntityById( "thief" );
			_thief.add( new Sleep( true, true ));
			_jinn = getEntityById( "jinn" );
			_sultan = getEntityById( "sultan" );
			_sultan.add( new Sleep( true, true ));
			
			_thief.add( new ValidHit( "behind_dias", "dias_top", "carpet" ));
			Display( _sultan.get( Display )).visible = false;
			Display( _thief.get( Display )).visible = false;
			DisplayUtils.moveToOverUnder( Display( _thief.get( Display )).displayObject, Display( getEntityById( "dias" ).get( Display )).displayObject, false );
			
			_characterGroup.addFSM( _sultan );
			_characterGroup.addFSM( _thief );
			_characterGroup.addAudio( _sultan );
			_characterGroup.addAudio( _thief );
			_audioGroup.addAudioToEntity( _jinn );
			
			CharUtils.setAnim( _thief, StandNinja, true );
			super.addGenieWaveMotion( _jinn );
		}
		
		override protected function eventTriggered( event:String, makeCurrent:Boolean=true, init:Boolean=false, removeEvent:String=null ):void
		{
			var dialog:Dialog;
			
			if( event == _events.USE_LAMP )
			{
				if( shellApi.checkEvent( _events.GENIE_IN_LAMP_ROOM ) && !shellApi.checkEvent( _events.THIEF_TRANSFORMED ))
				{
					if( CharUtils.hasSpecialAbility( player, MagicCarpet))
					{
						CharUtils.removeSpecialAbilityByClass( player, MagicCarpet, true );
						
						var motionThreshold:MotionThreshold 	= 	new MotionThreshold( "velocity", "==" );
						motionThreshold.axisValue 				= 	"y";
						motionThreshold.threshold 				= 	0;
						motionThreshold.entered.addOnce( moveToLampPosition );
						
						player.add( motionThreshold );
					}
					
					else
					{
						moveToLampPosition();
					}
				}
				else
				{
					dialog = player.get( Dialog );
					dialog.sayById( _events.CANT_USE_LAMP );
				}
			}
			
			super.eventTriggered( event, makeCurrent, init, removeEvent );
		}
		
		private function moveToLampPosition():void
		{
			var destination:Destination = CharUtils.moveToTarget( player, 840, 600, false, moveToTrapJinn );
			destination.validCharStates = new Vector.<String>;
			destination.validCharStates.push( CharacterState.STAND, CharacterState.WALK, CharacterState.FALL );
		}
		
		// IN-SCENE CINEMATIC TRYING TO CATCH THE JINN
		private function moveToTrapJinn( player:Entity ):void
		{
			SceneUtil.lockInput( this );
			
			ToolTipCreator.removeFromEntity( _jinn );
			ToolTipCreator.removeFromEntity( _sultan );
			ToolTipCreator.removeFromEntity( _thief );
			
			var holderSpatial:Spatial = player.get( Spatial );
			var faceRight:Boolean = Spatial( _jinn.get( Spatial )).x < holderSpatial.x ? false : true;
			
			CharUtils.setDirection( player, faceRight );
			CharUtils.setDirection( _jinn, !faceRight );
			
			SkinUtils.setSkinPart( player, SkinUtils.ITEM, LAMP, true );

			
			CharUtils.setAnim( player, Sword, false, 0, 0, true );
			
			var timeline:Timeline = player.get( Timeline );
			timeline.handleLabel( "fire", Command.create( stopTimeline, player ));
			
			var dialog:Dialog = player.get( Dialog );
			dialog.sayById( "capture_jinn" );
			dialog.complete.addOnce( thiefAppears );
		}
		
		private function stopTimeline( character:Entity ):void
		{
			var timeline:Timeline = character.get( Timeline );
			timeline.stop();
		}
		
		private function thiefAppears( dialogData:DialogData = null ):void
		{
			Sleep( _thief.get( Sleep )).sleeping = false;
			Display( _thief.get( Display )).visible = true;
			var spatial:Spatial = player.get( Spatial );
			
			var destination:Destination = CharUtils.moveToTarget( _thief, spatial.x, spatial.y, true, launchPlayer );
			destination.validCharStates = new Vector.<String>;
			destination.validCharStates.push( CharacterState.STAND, CharacterState.RUN, CharacterState.WALK );
		}
		
		private function launchPlayer( entity:Entity ):void
		{
			_thief.remove( ValidHit );
			_thief.add( new ValidHit( "pedestal", "dias_top", "carpet", "wall" ));
			
			CharUtils.setAnim( _thief, SkidNinja, false, 0, 0, true );
			SceneUtil.setCameraTarget( this, _window );
			
			AudioUtils.play( this, SoundManager.EFFECTS_PATH + "hurdle_bump_01.mp3", 1 );
			
			var timeline:Timeline = _thief.get( Timeline );
			timeline.handleLabel( "beginning", skidHandler );
			
			var spatial:Spatial 	=	player.get( Spatial );
			CharUtils.setAnim( _jinn, Tremble, false, 0, 0, true );
			
			// move thief to above the dias
			DisplayUtils.moveToOverUnder( Display( _thief.get( Display )).displayObject, Display( _window.get( Display )).displayObject, true );
		}
		
		private function skidHandler():void
		{		
			var motion:Motion 			= 	player.get( Motion );
			motion.velocity 			= 	new Point( -150, -300 );
			
			var motionThreshold:MotionThreshold = new MotionThreshold();
			motionThreshold.property 	= 	"velocity";
			motionThreshold.axisValue 	= 	"y";
			motionThreshold.operator 	= 	">=";
			motionThreshold.threshold 	= 	0;
			motionThreshold.entered.addOnce( readyMotionThreshold );
			player.add( motionThreshold );
			
			CharUtils.setState( player, CharacterState.HURT );
			
			// GIVE LAMP TO THE THIEF
			SkinUtils.emptySkinPart( player, SkinUtils.ITEM );
			SkinUtils.setSkinPart( _thief, SkinUtils.ITEM, LAMP );
		}
		
		private function readyMotionThreshold():void
		{
			var motionThreshold:MotionThreshold = player.get( MotionThreshold );
			motionThreshold.operator = "==";
			motionThreshold._firstCheck = true;
			
			motionThreshold.entered.addOnce( playerDazed );
		}
		
		private function playerDazed():void
		{
			CharUtils.setAnim( player, Dizzy );
			MotionUtils.zeroMotion( player );
			Spatial( player.get( Spatial )).rotation = 0;
			
			var motion:Motion = player.get( Motion );
			CharacterMotionControl( player.get( CharacterMotionControl )).spinning = false;
			motion.rotationAcceleration = motion.rotationVelocity = motion.previousRotation = 0;
			addressJinn();
		}
		
		private function addressJinn():void
		{
			var path:Vector.<Point> = new <Point>[ new Point( 950, 350 ), new Point( 1000, 520 )]; 
			CharUtils.followPath( _thief, path );
			
			var triggerHit:TriggerHit = new TriggerHit( null, new <String>[ "thief" ]);
			triggerHit.triggered = new Signal();
			triggerHit.triggered.addOnce( positionForConfrontation );
			
			getEntityById( "dias_top" ).add( triggerHit );
		}
		
		private function positionForConfrontation():void
		{
			var timeline:Timeline 	=	_thief.get( Timeline );
			timeline.handleLabel( "startBreath", confrontation );
		}
		
		private function confrontation():void
		{
			// MOVE JINN BACK
			var tween:Tween = new Tween();
			var spatial:Spatial = _jinn.get( Spatial );
			
			SkinUtils.setEyeStates( _jinn, EyeSystem.OPEN, EyeSystem.FRONT );
			tween.to( spatial, 1, { x : spatial.x + 20, y : spatial.y - 100 });
			_jinn.add( tween );
			CharUtils.setAnim( _jinn, Grief, false, 0, 0, true );
			
			CharUtils.setState( _thief, CharacterState.STAND );
			
			var motionControl:CharacterMotionControl = _thief.get( CharacterMotionControl );
			motionControl.spinning = false;
			
			spatial = _thief.get( Spatial );
			spatial.rotation = 0;
			confrontJinn();
			
			getEntityById( "dias_top" ).remove( TriggerHit );
		}
		
		private function confrontJinn():void
		{
			CharUtils.setDirection( _thief, true );		
			
			var dialog:Dialog = _thief.get( Dialog );
			dialog.faceSpeaker = false;
			dialog.sayById( "no_more_running" );
			dialog.complete.addOnce( noMoreRunning );
			
			enterSultan();
		}
		
		private function noMoreRunning( dialogData:DialogData ):void
		{
			var lamp:Entity = SkinUtils.getSkinPartEntity( _thief, SkinUtils.ITEM );
			
			_smokePuffGroup.trapJinn( _jinn, _thief, transferPowers, lamp, "jinn_powers" );
		}
		
		private function enterSultan():void
		{
			Sleep( _sultan.get( Sleep )).sleeping = false;
			Display( _sultan.get( Display )).visible = true;
			
			var path:Vector.<Point> = new <Point>[ new Point( 580, 580 ), new Point( 770, 670 ), new Point( 870, 670 )];
			CharUtils.followPath( _sultan, path, begThief, true );
		}
		
		private function begThief( sultan:Entity ):void
		{
			CharUtils.setAnim( _sultan, Sword );
			
			var dialog:Dialog = _sultan.get( Dialog );
			dialog.faceSpeaker = false;
			dialog.sayById( "wait" );
			
			var timeline:Timeline = _sultan.get( Timeline );
			timeline.handleLabel( "hold", Command.create( stopTimeline, _sultan ));
		}
		
		private function transferPowers( dialogData:DialogData ):void
		{			
			Dialog( _jinn.get( Dialog )).sayById( "yes_master" );
			Dialog( _jinn.get( Dialog )).complete.addOnce( startTheMagic );
			
			CharUtils.setState( player, CharacterState.STAND );
			SkinUtils.setSkinPart( player, SkinUtils.EYES, "eyes", false );
			
			_smokePuffGroup.startSpellCasting( _jinn );
		}
		
		private function startTheMagic( dialogData:DialogData ):void
		{
			_smokePuffGroup.castSpell( _jinn, new <Entity>[ _jinn, _thief ], spellCast );
		}
		
		private function spellCast():void
		{			
			var lookData:LookData = new LookData( null );
			lookData.applyLook( "male", 0xdcba71, 0x0, EyeSystem.SQUINT, HUMAN_JINN, "78", null, HUMAN_JINN, HUMAN_JINN, HUMAN_JINN, HUMAN_JINN, "", "empty", "", "", "empty" );
			SkinUtils.applyLook( _jinn, lookData );
			
			lookData = new LookData( null );
			lookData.applyLook( "female", 0x6bdbb6, 0x1b362d, EyeSystem.SQUINT, JINN_THIEF, "15", "an2_master2", JINN_THIEF, "an_genie2", JINN_THIEF, "an_princess", "", "empty" );
			SkinUtils.applyLook( _thief, lookData, true, newJinnInTown );
			
			Display( _jinn.get( Display )).alpha = 0;
			Display( _thief.get( Display )).alpha = 0;
			
			_characterGroup.addFSM( _jinn );
			_characterGroup.addAudio( _jinn );
			_characterGroup.removeFSM( _thief );
			
			_jinn.remove( WaveMotion );
			_jinn.remove( SpatialAddition );
			
			Spatial( _thief.get( Spatial )).y -= 20;
			
			var lamp:Entity = getEntityById( "lamp" );
			Display( lamp.get( Display )).visible = true;
			
			Timeline( _thief.get( Timeline )).play();
			Timeline( _sultan.get( Timeline )).play();
			
			_smokePuffGroup.removeLampSmokes( false, true );
			_smokePuffGroup.releaseJinn( _jinn );
		}
		
		private function newJinnInTown( ...args ):void
		{
			super.addGenieWaveMotion( _thief, true );
			var motion:Motion = _jinn.get( Motion );
			motion.acceleration = new Point( 0, MotionUtils.GRAVITY );
			motion.maxVelocity 	= new Point( 1000, 1000 );
			
			
			AudioUtils.play( this, SoundManager.MUSIC_PATH + "catastrophicevent.mp3", 1 );
			Display( _jinn.get( Display )).alpha = 1;
			Display( _thief.get( Display )).alpha = 1;
			
			CharUtils.setAnim( _jinn, Grief );
			CharUtils.setAnim( _thief, Proud );
						
			var timeline:Timeline = _thief.get( Timeline );
			timeline.handleLabel( "ending", thiefGloat );
		}
		
		private function thiefGloat():void
		{
			var dialog:Dialog = _thief.get( Dialog );
			dialog.sayById( "my_kingdom" );
			dialog.complete.addOnce( startTheTerror );
			
			_thief.add( new Tween());
			thiefRoam( true );
		}
		
		private function startTheTerror( dialogData:DialogData ):void
		{
			// lets have her float to the left and right and laugh while the sultan cries to you
			var dialog:Dialog = _sultan.get( Dialog );
			CharUtils.setAnim( _sultan, Cry );
			
			dialog.faceSpeaker = true;
			dialog.sayById( "stop_her" );
			dialog.complete.addOnce( thiefStartsSpell );
		}
		
		private function thiefRoam( toRight:Boolean ):void
		{
			if( !readyToEscape )
			{
				CharUtils.setDirection( _thief, toRight );
				CharUtils.setAnim( _thief, Laugh );
				var spatial:Spatial = _thief.get( Spatial );
				var tween:Tween = _thief.get( Tween );
				
				var targetPosition:Number = toRight ? spatial.x + 100 : spatial.x - 100;
				tween.to( spatial, 1, { x : targetPosition, onComplete : thiefRoam, onCompleteParams : [ !toRight ]});
			}
		}
		
		private function thiefStartsSpell( dialogData:DialogData ):void
		{
			readyToEscape = true;
			_smokePuffGroup.startSpellCasting( _thief, true );
			CharUtils.setDirection( _thief, false );
			CharUtils.setDirection( _sultan, true );
			
			SkinUtils.setEyeStates( _sultan, EyeSystem.SQUINT );
			
			var dialog:Dialog = _thief.get( Dialog );
			dialog.sayById( "not_likely" );
			dialog.complete.addOnce( thiefCastsSpell );
		}
		
		private function thiefCastsSpell( dialogData:DialogData ):void
		{
			CharUtils.setAnim( _sultan, Grief );
			CharUtils.setAnim( player, Grief );
			
			var faceRight:Boolean = ( Spatial( _thief.get( Spatial )).x < Spatial( _window.get( Spatial )).x ) ? true : false;
			CharUtils.setDirection( _thief, faceRight );
			
			_smokePuffGroup.castSpell( _thief, new <Entity>[ _window ], thiefBreaksWindow, null, false, false, true );
		}
		
		private function thiefBreaksWindow():void
		{
			var lightOverlay:Entity = getEntityById( "lightLayer" );
			var display:Display;
			
			var lightOverlaySprite:Sprite = new Sprite();
			lightOverlaySprite.mouseEnabled = false;
			lightOverlaySprite.mouseChildren = false;
			lightOverlaySprite.graphics.clear();
			lightOverlaySprite.graphics.beginFill( 0xFFFFFF, 1 );
			lightOverlaySprite.graphics.drawRect( 0, 0, super.shellApi.viewportWidth, super.shellApi.viewportHeight );
			overlayContainer.addChild( lightOverlaySprite );
			
			AudioUtils.play( this, SoundManager.EFFECTS_PATH + "glass_break_03.mp3", 2 );
			display = new Display( lightOverlaySprite );
			display.isStatic = true;
			display.alpha = 0;
			
			lightOverlay.add( display );
			
			var tween:Tween = new Tween();
			tween.to( display, 2, { alpha : 1, onComplete : endExplosion, onCompleteParams : [ lightOverlay ]});
			lightOverlay.add( tween );	
			
			// Add the particle effect for the broken window
			var timeline:Timeline = _window.get( Timeline );
			timeline.gotoAndStop( 1 );
			
			var emitter2D:Emitter2D = new Emitter2D();
			var bitmapData:BitmapData = BitmapUtils.createBitmapData( _hitContainer[ "window_piece" ]);
				
			emitter2D = new Emitter2D();
			emitter2D.counter = new Blast( 20 );
			emitter2D.addInitializer( new BitmapImage( bitmapData, true, 20 ));
			emitter2D.addInitializer( new Position( new EllipseZone( new Point( 0, 0 ), 25, 25 )));
			emitter2D.addInitializer( new Lifetime( .5 ));
			emitter2D.addInitializer( new Velocity( new EllipseZone( new Point( 0, 0 ), 800, 800 )));
			
			emitter2D.addAction( new RotateToDirection());
			emitter2D.addAction( new Age());
			emitter2D.addAction( new Move());
			
			var spatial:Spatial = _window.get( Spatial );
			EmitterCreator.create( this, _hitContainer, emitter2D, spatial.x, spatial.y, null, "shatterEmitter" );	
		}
		
		private function endExplosion( lightOverlay:Entity ):void
		{
			var tween:Tween = lightOverlay.get( Tween );
			var display:Display = lightOverlay.get( Display );
			tween.to( display, 2, { alpha : 0, onComplete : thiefEscapes });
		}
		
		private function thiefEscapes():void
		{
			CharUtils.setAnim( _thief, Laugh );
			
			var timeline:Timeline = _thief.get( Timeline );
			timeline.handleLabel( "ending", thiefOutTheWindow );
		}
		
		private function thiefOutTheWindow():void
		{
			var spatial:Spatial = _thief.get( Spatial );
			Display( _thief.get( Display )).setContainer( Display( getEntityById( "sky" ).get( Display )).displayObject );
			Display( _smokePuffGroup._tailSmoke.get( Display )).setContainer( Display( getEntityById( "sky" ).get( Display )).displayObject );
			
			var tween:Tween = new Tween();
			_thief.add( tween );
			
			CharUtils.setDirection( _thief, false );
			tween.to( spatial, 2, { x : 745, y : 270, onComplete : thiefEscaped }); 
		}
		
		private function thiefEscaped():void
		{
			var dialog:Dialog = _sultan.get( Dialog );
			CharUtils.setAnim( _sultan, Cry );
			
			dialog.sayById( "do_anything" );
			dialog.complete.addOnce( readyCarpet );
		}
		
		private function readyCarpet( dialogData:DialogData ):void
		{
			CharUtils.setDirection( _sultan, true );
			SkinUtils.setEyeStates( _sultan, EyeSystem.SQUINT );
			
			var destination:Destination = CharUtils.moveToTarget( player, 1030, 470, true, loadCarpet );
			destination.validCharStates = new Vector.<String>;
			destination.validCharStates.push( CharacterState.STAND );
		}
		
		private function loadCarpet( player:Entity ):void
		{
			CharUtils.setDirection( player, false );
			CharUtils.addSpecialAbility( player, new SpecialAbilityData( MagicCarpet ), true );
			CharUtils.setAnim( _jinn, Stand );
			
			Display( player.get( Display )).setContainer( Display( getEntityById( "sky" ).get( Display )).displayObject );
			_characterGroup.removeFSM( player );
			
			var spatial:Spatial = player.get( Spatial );
			var tween:Tween = new Tween();
			player.add( tween );
			tween.to( spatial, 2, { x : 745, y : 270, onComplete : loadChase });
		}
		
		private function loadChase():void
		{
			// remove lamp at this point, since other characters have it now.
			// but don't remove it so soon as to if it crashes it breaks rest of game
			shellApi.removeItem(_events.GOLDEN_LAMP);
			shellApi.completeEvent( _events.THIEF_TRANSFORMED );
			shellApi.loadScene( SkyChase );
		}
	}
}