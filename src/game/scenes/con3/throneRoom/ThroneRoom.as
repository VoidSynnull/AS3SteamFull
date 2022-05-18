package game.scenes.con3.throneRoom
{	
	import flash.display.BitmapData;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.geom.ColorTransform;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Motion;
	import engine.components.OwningGroup;
	import engine.components.Spatial;
	import engine.components.SpatialAddition;
	import engine.components.Tween;
	import engine.creators.InteractionCreator;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import fl.motion.easing.Quadratic;
	
	import game.components.animation.FSMControl;
	import game.components.entity.Dialog;
	import game.components.entity.Sleep;
	import game.components.entity.character.CharacterMotionControl;
	import game.components.hit.HitTest;
	import game.components.motion.FollowTarget;
	import game.components.motion.ShakeMotion;
	import game.components.motion.Threshold;
	import game.components.motion.WaveMotion;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.BitmapSequence;
	import game.components.timeline.Timeline;
	import game.creators.entity.BitmapTimelineCreator;
	import game.creators.entity.EmitterCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.WaveMotionData;
	import game.data.animation.entity.character.FistPunch;
	import game.data.animation.entity.character.Grief;
	import game.data.animation.entity.character.PlacePitcher;
	import game.data.animation.entity.character.Proud;
	import game.data.animation.entity.character.RobotDance;
	import game.data.animation.entity.character.Stand;
	import game.data.animation.entity.character.Sword;
	import game.data.animation.entity.character.Tremble;
	import game.data.display.BitmapWrapper;
	import game.data.scene.characterDialog.DialogData;
	import game.data.scene.hit.MovingHitData;
	import game.scene.SceneSound;
	import game.scene.template.CharacterGroup;
	import game.scenes.con3.Con3Scene;
	import game.scenes.con3.portal.Portal;
	import game.scenes.con3.shared.BarrierGroup;
	import game.scenes.con3.shared.ElectricPulseGroup;
	import game.scenes.con3.shared.GauntletResponder;
	import game.scenes.con3.shared.PortalGroup;
	import game.scenes.con3.shared.WrappedSignal;
	import game.scenes.con3.throneRoom.components.InwardSpiralComponent;
	import game.scenes.con3.throneRoom.systems.InwardSpiralSystem;
	import game.scenes.survival1.shared.components.TriggerHit;
	import game.scenes.survival1.shared.systems.TriggerHitSystem;
	import game.systems.actionChain.ActionChain;
	import game.systems.actionChain.actions.CallFunctionAction;
	import game.systems.actionChain.actions.MoveAction;
	import game.systems.actionChain.actions.PanAction;
	import game.systems.actionChain.actions.TalkAction;
	import game.systems.actionChain.actions.WaitAction;
	import game.systems.entity.character.states.CharacterState;
	import game.systems.motion.ShakeMotionSystem;
	import game.systems.motion.ThresholdSystem;
	import game.systems.motion.WaveMotionSystem;
	import game.util.AudioUtils;
	import game.util.BitmapUtils;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.GeomUtils;
	import game.util.PerformanceUtils;
	import game.util.PlatformUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.Fade;
	import org.flintparticles.common.actions.ScaleImage;
	import org.flintparticles.common.counters.Blast;
	import org.flintparticles.common.counters.Random;
	import org.flintparticles.common.displayObjects.Droplet;
	import org.flintparticles.common.displayObjects.Ring;
	import org.flintparticles.common.initializers.BitmapImage;
	import org.flintparticles.common.initializers.ColorInit;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.MutualGravity;
	import org.flintparticles.twoD.actions.RotateToDirection;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.EllipseZone;
	import org.osflash.signals.Signal;
	
	public class ThroneRoom extends Con3Scene
	{
		public function ThroneRoom()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/con3/throneRoom/";
			super.init(container);
		}
		
		override protected function addCharacters():void
		{
			super.addCharacters();
			
			// PRELOAD ANIMATIONS FOR SNEAKING
			var characterGroup:CharacterGroup = super.getGroupById( CharacterGroup.GROUP_ID ) as CharacterGroup;
			characterGroup.preloadAnimations( new <Class>[ RobotDance ]);
		}
		
		override protected function addBaseSystems():void
		{
			super.addBaseSystems();
			
			addSystem( new WaveMotionSystem());
			addSystem( new InwardSpiralSystem());
			addSystem( new ThresholdSystem());
			addSystem( new TriggerHitSystem());
			
			if( PlatformUtils.isDesktop )
			{
				addSystem( new ShakeMotionSystem());
			}
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();
		}
		
		override public function destroy():void
		{
			if( _laserSequence )
			{
				_laserSequence.destroy();
				_laserSequence= null;
			}
			if( _wiresSequence )
			{
				_wiresSequence.destroy();
				_wiresSequence= null;
			}
			if( _coreWiresBackSequence )
			{
				_coreWiresBackSequence.destroy();
				_coreWiresBackSequence= null;
			}
			if( _coreWiresFrontSequence )
			{
				_coreWiresFrontSequence.destroy();
				_coreWiresFrontSequence= null;
			}
			if( _coreSequence )
			{
				_coreSequence.destroy();
				_coreSequence= null;
			}
			
			super.destroy();
		}
		
		/**
		 * ALL ASSETS READY
		 */
		override public function setUpScene():void
		{
			super.setUpScene();
			
			var electricPulseGroup:ElectricPulseGroup = this.addChildGroup( new ElectricPulseGroup()) as ElectricPulseGroup;
			electricPulseGroup.createPanels( _hitContainer[ PANEL + "1" ], this, _hitContainer, startLift, TAB_BLOCKER, LIFT, endLift );
			
			var barrierGroup:BarrierGroup = this.addChildGroup( new BarrierGroup()) as BarrierGroup;
			barrierGroup.createBarriers( this, _hitContainer );
			
			_portalGroup = this.addChildGroup( new PortalGroup()) as PortalGroup;
			_portalGroup.createPortal( this, _hitContainer );
			
			if( !shellApi.checkItemEvent( _events.MEDAL_CON3 ))
			{
				createPulseResponders();
				setupAssets(); 
				hideFutureAssets();
				setupOmegonDialog();
				tweekLasers();
				checkUpOnActor();
			}
			else
			{
				removePreBattleAssets();
			}
			
			var spatial:Spatial = player.get( Spatial );
			spatial.x = this.sceneData.startPosition.x;
			spatial.y = this.sceneData.startPosition.y;			
		}
		
		/**
		 * CRYSTAL CORE, WIRE, LASER SETUP
		 */
		private function createPulseResponders():void
		{
			var entity:Entity;
			var entities:Vector.<Entity> = new <Entity>[ getEntityById( TAB_BLOCKER + "1" ), getEntityById( TAB_BLOCKER + "2" ), getEntityById( TAB_BLOCKER + "3" )];
			var gauntletResponder:GauntletResponder;
			var spatial:Spatial;
			
			for each( entity in entities )
			{
				gauntletResponder = entity.get( GauntletResponder );
				gauntletResponder.oneLoop = false;
				
				spatial = entity.get( Spatial );
				spatial.y = 572;
			}
		}
		
		private function removePreBattleAssets():void
		{
			var asset:String;
			var assets:Vector.<String> = new <String>[ "after", "portal", TAB_BLOCKER + "1", TAB_BLOCKER + "2", TAB_BLOCKER + "3"
														, CORE_WIRES + "back", CORE_WIRES + "front", "force_shield"
														, CORE, WIRES, CORE_LASER + "1", CORE_LASER + "2"
														, CORE_LASER + "3", CORE_LASER + "0", "force_field", THRONE, TARGET + "_" + CORE
														, "henchbot1", "henchbot2", "omegon", "meowbot"
														, BATTERY + "1", BATTERY + "2", BATTERY + "3", TAB + "1", TAB + "2", TAB + "3" ];
			
			for each( asset in assets )
			{
				if( getEntityById( asset ))
				{
					removeEntity( getEntityById( asset ));
				}
				else
				{
					_hitContainer.removeChild( _hitContainer[ asset ]);
				}
			}
			
			getEntityById( "panel1" ).remove( SceneInteraction );
			getEntityById( "panel2" ).remove( SceneInteraction );
			getEntityById( "panel3" ).remove( SceneInteraction );
		}
		
		private function setupAssets():void
		{
			// BATTERY SLOTS
			var audio:Audio;
			var battery:Entity;
			var clip:MovieClip;
			var coreLaser:Entity;
			var coreLaserBeam:Entity;
			var entity:Entity;
			var follower:Entity;
			var number:int;
			var timeline:Timeline;

			clip = _hitContainer[ CORE_LASER + "1" ];
			_laserSequence = BitmapTimelineCreator.createSequence( clip, this, PerformanceUtils.defaultBitmapQuality + 0.3);
								
			for( number = 1; number < 4; number ++ )
			{
				// LASER BASES
				coreLaser = makeEntity( _hitContainer[ CORE_LASER + number ], _laserSequence, true );
				// BATTERIES
				battery = makeEntity( _hitContainer[ BATTERY + number ], null, true );
				// CORE LASERS
				
				if( shellApi.checkEvent( _events.SODA_PLACED + number ))
				{
					Audio( coreLaser.get( Audio )).playCurrentAction( TRIGGER );
					Timeline( coreLaser.get( Timeline )).gotoAndStop( "on" );
					
					crystalState++;
				}
				else
				{
					Display( battery.get( Display )).alpha = 0;
					Timeline( coreLaser.get( Timeline )).gotoAndStop( "off" );
				}
				
				entity = getEntityById( TAB_BLOCKER + number );
				follower = makeEntity(_hitContainer[ TAB + number ], null, true );
				
				follower.add( new FollowTarget( entity.get( Spatial )));
				Display( entity.get( Display )).alpha = 0;
			}	
			
			clip = _hitContainer[ "batteryClick" ];
			if( crystalState == 4 )
			{
				crystalReady();
				_hitContainer.removeChild( clip );
			}
			else
			{
				makeEntity( clip, null, false, weirdAlienMachine ); 
			}
			
			for( number = 1; number < 3; number ++ )
			{
				entity = getEntityById( LIFT + number );
				follower = makeEntity(_hitContainer[ LIFT_BASE + number ], null, true );
				
				follower.add( new FollowTarget( entity.get( Spatial )));
				Display( entity.get( Display )).alpha = 0;
			}
			
			coreLaser = makeEntity( _hitContainer[ CORE_LASER + "0" ], null, true );
			Audio( coreLaser.get( Audio )).playCurrentAction( TRIGGER );

			// SETUP CRYSTAL TARGET
			var target:Entity = getEntityById( TARGET + "_" + CORE );
			var sig:WrappedSignal = new WrappedSignal();
			sig.signal.add( shatterCrystal );
			target.add( sig );
			
			// SODA TO CRYSTAL WIRES
			_wiresSequence = BitmapTimelineCreator.createSequence( _hitContainer[ WIRES ], true, PerformanceUtils.defaultBitmapQuality + 0.3);
			entity = makeEntity( _hitContainer[ WIRES ], _wiresSequence, false );
			Timeline( entity.get( Timeline )).gotoAndStop( crystalState - 1 );
			
			// BACK WIRES
			_coreWiresBackSequence = BitmapTimelineCreator.createSequence( _hitContainer[ CORE_WIRES + "back" ], true, PerformanceUtils.defaultBitmapQuality + 0.3);
			entity = makeEntity( _hitContainer[ CORE_WIRES + "back" ], _coreWiresBackSequence, false );
			timeline = entity.get( Timeline );
			if( crystalState > 3 )
			{
				timeline.gotoAndStop( 2 );
			}
			else
			{
				timeline.gotoAndStop( crystalState - 1 );
			}
			
			// FRONT WIRES
			_coreWiresFrontSequence = BitmapTimelineCreator.createSequence( _hitContainer[ CORE_WIRES + "front" ], true, PerformanceUtils.defaultBitmapQuality + 0.3);
			entity = makeEntity( _hitContainer[ CORE_WIRES + "front" ], _coreWiresFrontSequence, false );
			if( crystalState > 3 )
			{
				Timeline( entity.get( Timeline )).gotoAndStop( 1 );
			}	
			
			// CORE
			_coreSequence = BitmapTimelineCreator.createSequence( _hitContainer[ CORE ], true, PerformanceUtils.defaultBitmapQuality + 0.3);
			entity = makeEntity( _hitContainer[ CORE ], _coreSequence, true, critiqueCrystal );
			timeline = entity.get( Timeline );
			timeline.gotoAndStop( crystalState - 1 );
			
			// FORCE FIELD
			if( PlatformUtils.isDesktop )
			{
				entity.add( new ShakeMotion( new EllipseZone( new Point( 0, 0 ), crystalState - 1, crystalState -1 ))).add( new SpatialAddition());
				pulseForceField( makeEntity( _hitContainer[ "force_field" ], null ));
			}
			
			// THRONE
			entity = makeEntity( _hitContainer[ THRONE ], null, true );
			
			if( PlatformUtils.isDesktop )
			{
				entity.add( new ShakeMotion( new EllipseZone( new Point( 0, 0 ), crystalState - 1, crystalState -1 ))).add( new SpatialAddition());
			}
			
			// SET CRYSTAL SHAKE SOUNDS
			audio = getEntityById( THRONE ).get( Audio );
			if( crystalState > 1 )
			{		
				audio.playCurrentAction( TRIGGER + "1" );
				if( crystalState > 2)
				{
					audio.playCurrentAction( TRIGGER + "2" );
					if( crystalState > 3 )
					{
						audio.playCurrentAction( TRIGGER + "3" );	
						audio.playCurrentAction( TRIGGER + "4" );				
					}
				}
			}
		}
		
		private function makeEntity( clip:MovieClip, sequence:BitmapSequence = null, addAudioRange:Boolean = true, interactionHandler:Function = null, isEmpty:Boolean = false ):Entity
		{
			var display:Display;
			var entity:Entity;
			var interaction:Interaction;
			var timeline:Timeline;
			var wrapper:BitmapWrapper;
			
			if( sequence )
			{
				entity = EntityUtils.createMovingTimelineEntity( this, clip, null, false );
				entity = BitmapTimelineCreator.convertToBitmapTimeline( entity, clip, true, sequence, PerformanceUtils.defaultBitmapQuality + 0.3);
			}
			else
			{
				if( !isEmpty )
				{
					wrapper = super.convertToBitmapSprite( clip, null, true, PerformanceUtils.defaultBitmapQuality + 0.3);	
					entity = EntityUtils.createSpatialEntity( this, wrapper.sprite );
				}
				else
				{
					entity = EntityUtils.createSpatialEntity( this, clip );
				}
			}
			
			entity.add( new Id( clip.name ));
			_audioGroup.addAudioToEntity( entity );
			
			if( addAudioRange )
			{
				entity.add( new AudioRange( 500 ));
			}
			
			if( interactionHandler )
			{
				if( !entity.group || entity.get( OwningGroup ))
				{
					entity.group = this;
					entity.add( new OwningGroup( this ));
				}
				ToolTipCreator.addToEntity( entity );
				interaction = InteractionCreator.addToEntity( entity, [ InteractionCreator.CLICK ]);
				interaction.click.add( interactionHandler );
			}		
			
			return entity;
		}
		
		private function weirdAlienMachine( ...args ):void
		{
			var dialog:Dialog = player.get( Dialog );
			if( crystalState < 2 )
			{
				dialog.sayById( "pre_soda" );
			}
			else
			{
				dialog.sayById( "needs_more_soda" );
			}
		}
		
		/**
		 * READY AFTERMATH
		 */
		private function hideFutureAssets():void
		{
			// HIDE PORTAL AND EXPLOSION AFTERMATH
			var afterMath:Entity = getEntityById( "after" );
			var display:Display = afterMath.get( Display );
			display.visible = false;
			var sleep:Sleep = afterMath.get( Sleep );
			if( !sleep )
			{
				sleep = new Sleep();
				afterMath.add( sleep );
			}
			
			sleep.sleeping = true;
			sleep.ignoreOffscreenSleep = false;
		}
		
		/** 
		 * RESOLVING GLOVES
		 * 		- LIFTS
		 */ 		
		private function startLift( responder:Entity ):void
		{
			var motion:Motion = responder.get( Motion );
			motion.maxVelocity = new Point( Infinity, Infinity );
			
			var movingHitData:MovingHitData = responder.get( MovingHitData );
			movingHitData.pause = false;
			
			var gauntletResponder:GauntletResponder = responder.get( GauntletResponder );
			gauntletResponder.iteration = 0;
		}
		
		private function endLift( controller:Entity, responder:Entity ):void
		{
			var gauntletResponder:GauntletResponder = responder.get( GauntletResponder );
			if( gauntletResponder.invalidate ) 
			{
				var movingHitData:MovingHitData = responder.get( MovingHitData );
				var motion:Motion = responder.get( Motion );
				
				movingHitData.pause = true;
				movingHitData.pointIndex = 0;
				motion.maxVelocity = new Point( 0, 0 );
				
				var timeline:Timeline = controller.get( Timeline );
				timeline.play();
				
				var spatial:Spatial = responder.get( Spatial );
				
				spatial.x = gauntletResponder.endPoint.x;
				spatial.y = gauntletResponder.endPoint.y;
				gauntletResponder.invalidate = false;
				
				var audio:Audio = controller.get( Audio );
				audio.stopActionAudio( TRIGGER );
				
				audio = responder.get( Audio );
				audio.stopActionAudio( TRIGGER );
			}
			else if( gauntletResponder.oneLoop )
			{
				gauntletResponder.invalidate = true;
			}
			else
			{
				if( gauntletResponder.iteration == gauntletResponder.maxCycles )
				{
					var threshold:Threshold = responder.get( Threshold );
					if( !threshold )
					{
						threshold = new Threshold( "y", ">" );
						responder.add( threshold );
					}
					
					gauntletResponder.invalidate = true;
					threshold.threshold = gauntletResponder.endPoint.y;
					threshold.entered.addOnce( Command.create( endLift, controller, responder ));
				}
				else
				{
					gauntletResponder.iteration ++;
				}
			}
		}
		
		/**
		 * EVENT TRIGGERS
		 */
		override protected function eventTriggered( event:String, save:Boolean = true, init:Boolean = false, removeEvent:String = null ):void
		{
			if( player )
			{
				var dialog:Dialog = player.get( Dialog );
				var spatial:Spatial = player.get( Spatial );
			}
			if( event == _events.USE_SODA )
			{
				if( shellApi.checkEvent( _events.POWER_BOX_DESTROYED_ + "6" ) && spatial.x < 900 && spatial.y > 700 )
				{
					if( !shellApi.checkEvent( _events.SODA_PLACED + "1" ))
					{
						inspectBatterySlot( getEntityById( BATTERY + "1" ));
					}
					else if( !shellApi.checkEvent( _events.SODA_PLACED + "2" ))
					{
						inspectBatterySlot( getEntityById( BATTERY + "2" ));
					}
					else if( !shellApi.checkEvent( _events.SODA_PLACED + "3" ))
					{
						inspectBatterySlot( getEntityById( BATTERY + "3" ));
					}
				}
				else
				{
					dialog.sayById( "too_much_going_on_soda" );
				}
			}
			
			super.eventTriggered( event, save, init, removeEvent );
		}
		
		/**
		 * HELPER FUNCTIONS
		 */
		private function tweekLasers():void
		{
			if( !shellApi.checkEvent( _events.POWER_BOX_DESTROYED_ + "5" ))
			{
				var hit:Entity = getEntityById( "powerhit_5" );
				var hitTest:HitTest = hit.get( HitTest );
				hitTest.onEnter.addOnce( meltShield );
			}
		}
		
		override protected function panBackToPlayer():void
		{
			SceneUtil.setCameraTarget(this, this.player);
			if( !_box5Hit )
			{
				SceneUtil.lockInput( this, false );
			}
		}
		
		private function lostShield( ...args ):void
		{
			var dialog:Dialog = player.get( Dialog );
			dialog.sayById( "lost_shield" );
			dialog.complete.addOnce( unlock );
			
			_box5Hit = false;
		}
		
		private function unlock(...args):void
		{
			SceneUtil.lockInput(this, false);
			SceneUtil.setCameraTarget(this, player);
		}
		
		/**
		 * OMEGON CHIT CHAT
		 */
		private function setupOmegonDialog():void
		{
			var animations:Vector.<Class> = new <Class>[ RobotDance ];
			var henchbot1:Entity = getEntityById( "henchbot1" );
			var henchbot2:Entity = getEntityById( "henchbot2" );
			var omegon:Entity = getEntityById( "omegon" );
			var dialog:Dialog = getEntityById( "omegon" ).get( Dialog );
			dialog.faceSpeaker = false;
			var throne:Entity = getEntityById( THRONE );
			
			if( throne.has( SpatialAddition ))
			{
				omegon.add(throne.get( SpatialAddition ));
			}
			ToolTipCreator.removeFromEntity( omegon );
			
			Display( omegon.get( Display )).moveToBack();
			Display( getEntityById( "meowbot" ).get( Display )).moveToBack();
			ToolTipCreator.removeFromEntity( getEntityById( "meowbot" ));
			
			Display( henchbot1.get( Display )).moveToBack();
			Sleep( henchbot1.get( Sleep )).ignoreOffscreenSleep = true;
			Sleep( henchbot1.get( Sleep )).sleeping = false;
			ToolTipCreator.removeFromEntity( henchbot1 );
			
			Display( henchbot2.get( Display )).moveToBack();
			Sleep( henchbot2.get( Sleep )).ignoreOffscreenSleep = true;
			Sleep( henchbot2.get( Sleep )).sleeping = false;
			ToolTipCreator.removeFromEntity( henchbot2 );
			
			if( PlatformUtils.isDesktop )
			{
				CharUtils.setAnimSequence( henchbot1, animations, true );
				CharUtils.setAnimSequence( henchbot2, animations, true );
				Timeline( henchbot2.get( Timeline )).gotoAndPlay( 21 );
			}
			
			var triggerPlatform:Entity = getEntityById( "triggerPlat" );
			var triggerHit:TriggerHit = new TriggerHit( null, new <String>[ "player" ]);
			triggerHit.triggered = new Signal();
			triggerHit.triggered.add( startOmegonChitChat );
			triggerPlatform.add( triggerHit );
		}
		
		private function startOmegonChitChat(...args):void
		{	
			if( omegonIdle )
			{
				SceneUtil.setCameraTarget( this, getEntityById( "omegon" ));
				SceneUtil.lockInput( this );
				omegonIdle = false;
				
				var omegonComment:int = GeomUtils.randomInt( 1, 6 );
				var dialog:Dialog = getEntityById( "omegon" ).get( Dialog );
				dialog.sayById( "chit_chat" + omegonComment );
				dialog.complete.addOnce( panBackFromOmegon );
			}
		}
		
		private function panBackFromOmegon( dialogData:DialogData ):void
		{
			SceneUtil.setCameraTarget( this, player );
			SceneUtil.lockInput( this, false );
			omegonIdle = true;
		}

		
		
		private function pulseForceField( force_field:Entity, toOff:Boolean = true ):void
		{
			var display:Display = force_field.get( Display );
			var tween:Tween = force_field.get( Tween );
			if( !tween )
			{
				tween = new Tween();
				force_field.add( tween );
			}
			var toAlpha:Number = toOff ? 0.3 : 1;
			
			tween.to( display, BASIC_PULSE / crystalState, { alpha : toAlpha, onComplete : pulseForceField, onCompleteParams: [ force_field, !toOff ]});
		}
		
		
		/**
		 * WORLD GUY
		 */
		private function checkUpOnActor():void
		{
			if( !shellApi.checkEvent( _events.WORLD_GUY_SPOTTED ))		
			{
				SceneUtil.lockInput( this );
				SceneUtil.addTimedEvent( this, new TimedEvent( 1, 1, viewActor ));
				
				shellApi.completeEvent( _events.WORLD_GUY_SPOTTED );
			}
		}
		
		private function viewActor():void
		{
			var worldGuy:Entity = getEntityById( "worldGuy" );
			if( worldGuy )
			{
				SceneUtil.setCameraTarget( this, worldGuy );
				
				var dialog:Dialog = worldGuy.get( Dialog );
				dialog.sayById( "one_appearance" );
				dialog.faceSpeaker = false;
				dialog.complete.addOnce( unlock );
			}
			else
			{
				unlock();
			}
		}
		
		private function meltShield( hit:Entity, name:String ):void
		{
			var shield:Entity = SkinUtils.getSkinPartEntity( player, SkinUtils.ITEM );
			SceneUtil.lockInput( this );
			
			var spatial:Spatial = shield.get( Spatial );
			var display:Display = shield.get( Display );
			
			var wrapper:BitmapWrapper =	super.convertToBitmapSprite( display.displayObject, null, false );
			
			wrapper.sprite.x = spatial.x;
			wrapper.sprite.y = spatial.y;
			var colorTransform:ColorTransform = new ColorTransform();
			colorTransform.color = 0xD35A8A;
			wrapper.sprite.transform.colorTransform = colorTransform; 
			
			var copy:Entity = EntityUtils.createMovingEntity( this, wrapper.sprite, display.container );
			copy.add( new Id( "shieldCopy" ));
			display = copy.get( Display );
			display.alpha = 0;
			
			var tween:Tween = new Tween();
			tween.to( display, 3, { alpha : 1, onComplete : blowShield });
			copy.add( tween );
			_box5Hit = true;
		}
		
		private function blowShield():void
		{
			SkinUtils.emptySkinPart( player, SkinUtils.ITEM );
			shellApi.removeItem( _events.OLD_SHIELD );
			var fsmControl:FSMControl = player.get( FSMControl );
			CharUtils.stateDrivenOn( player );
			fsmControl.setState( CharacterState.HURT );
			
			removeEntity( getEntityById( "shieldCopy" ));
			
			var motion:Motion = player.get( Motion );
			motion.velocity.x = -100;
			motion.velocity.y = -100;
			
			SceneUtil.addTimedEvent( this, new TimedEvent( 1, 1, lostShield ));
			
			// EXPLOSION SOUND
			AudioUtils.play( this, SoundManager.EFFECTS_PATH + "sizzle_02.mp3" );
		}
		
		override protected function freeActor():void
		{
			var worldGuy:Entity = getEntityById( "worldGuy" );
			var dialog:Dialog = worldGuy.get( Dialog );
			dialog.allowOverwrite = true;
			dialog.faceSpeaker = true;
			
			DisplayUtils.moveToTop( Display( worldGuy.get( Display )).displayObject );
			
			// lock, talk, escape thru vent, unlock
			var actions:ActionChain = new ActionChain( this );
			actions.lockInput = true;
			actions.addAction(new CallFunctionAction( clearAnims ));
			actions.addAction(new PanAction( worldGuy ))
			actions.addAction( new TalkAction( worldGuy, "back_to_broadway" ));
			actions.addAction(new MoveAction( worldGuy,new Point( 2550, 300 )));
			actions.addAction(new MoveAction( worldGuy,new Point( 2700, 880 )));
			actions.addAction(new MoveAction( worldGuy,new Point( 2080, 880 )));
			actions.addAction(new WaitAction(1));
			actions.addAction(new CallFunctionAction( worldGuyOut ));
			actions.addAction(new PanAction( player ));
			actions.execute();
		}
		
		private function clearAnims():void
		{
			var worldGuy:Entity = getEntityById( "worldGuy" );
			CharUtils.setAnim( worldGuy, Stand, false, 0, 0, true );
		}
		
		private function worldGuyOut():void
		{
			removeEntity( getEntityById( "worldGuy" ));
			shellApi.completeEvent( _events.WORLD_GUY_RESCUED );
		}
		
		
		/**
		 * CRYSTAL CHALLENGE
		 */
		private function inspectBatterySlot( battery:Entity ):void
		{
			var charSpatial:Spatial = player.get( Spatial );
			var dialog:Dialog = player.get( Dialog );
			var spatial:Spatial = battery.get( Spatial );
			
			if( shellApi.checkHasItem( _events.SODA ))
			{
				SceneUtil.lockInput( this );
				CharUtils.moveToTarget( player, spatial.x + 40, charSpatial.y, true, Command.create( debateSoda, battery ));	
			}
			else
			{
				if( shellApi.checkEvent( _events.SODA_PLACED + "1" ) 
					|| shellApi.checkEvent( _events.SODA_PLACED + "2" ) 
					|| shellApi.checkEvent( _events.SODA_PLACED + "3" ))
				{
					dialog.sayById( "needs_more_soda" );					
				}
				else
				{
					dialog.sayById( "pre_soda" );
				}
			}
		}
		
		private function debateSoda( player:Entity, battery:Entity ):void
		{
			if( !shellApi.checkEvent( _events.FIRST_SODA ))
			{
				var dialog:Dialog = player.get( Dialog );
				dialog.sayById( "try_soda" );
				dialog.complete.addOnce( Command.create( addSoda, player, battery ));
				shellApi.completeEvent( _events.FIRST_SODA );
			}
			else
			{
				addSoda( null, player, battery );
			}
		}
		
		private function addSoda( data:DialogData = null, player:Entity = null, battery:Entity = null ):void
		{	
			var id:Id = battery.get( Id );
			var number:String = id.id.substr( id.id.length - 1 );
			
			switch( number )
			{
				case "1":
					CharUtils.setAnim( player, PlacePitcher );
					break;
				case "2":
					CharUtils.setAnim( player, FistPunch );
					break;
				case "3":
					CharUtils.setAnim( player, Sword );
					break;
			}
			
			if( shellApi.checkEvent( _events.GOT_SODA + "1" ) && shellApi.checkEvent( _events.HAS_SODA + "1" ))
			{
				shellApi.removeEvent( _events.HAS_SODA + "1" );
				
				if( !shellApi.checkEvent( _events.HAS_SODA + "2" ) && !shellApi.checkEvent( _events.HAS_SODA + "3" ))
				{
					shellApi.removeItem( _events.SODA );
				}
			}
			else if( shellApi.checkEvent( _events.GOT_SODA + "2" ) && shellApi.checkEvent( _events.HAS_SODA + "2" ))
			{
				shellApi.removeEvent( _events.HAS_SODA + "2" );
				
				if( !shellApi.checkEvent( _events.HAS_SODA + "1" ) && !shellApi.checkEvent( _events.HAS_SODA + "3" ))
				{
					shellApi.removeItem( _events.SODA );
				}
			}
			else if( shellApi.checkEvent( _events.GOT_SODA + "3" ) && shellApi.checkEvent( _events.HAS_SODA + "3" ))
			{
				shellApi.removeEvent( _events.HAS_SODA + "3" );
				
				if( !shellApi.checkEvent( _events.HAS_SODA + "1" ) && !shellApi.checkEvent( _events.HAS_SODA + "2" ))
				{
					shellApi.removeItem( _events.SODA );
				}
			}
			
			var entity:Entity = getEntityById( THRONE );
			
			var audio:Audio = getEntityById( THRONE ).get( Audio );
			switch( crystalState )
			{
				case 1:
					audio.playCurrentAction( TRIGGER + "1" );
					break;
				case 2:
					audio.playCurrentAction( TRIGGER + "2" );
					break;
				case 3:
					audio.playCurrentAction( TRIGGER + "3" );	
					audio.playCurrentAction( TRIGGER + "4" );				
					break;
				default:
					break;
			}
			
			var timeline:Timeline = player.get( Timeline );
			timeline.labelReached.add( Command.create( insertBattery, battery ));
		}
		
		private function insertBattery( label:String, battery:Entity ):void
		{
			var timeline:Timeline;
			var id:Id = battery.get( Id );
			var sodaPlacement:String = id.id.substr( id.id.length - 1 );
			var entity:Entity;
			var audio:Audio = battery.get( Audio );
			
			if( label == "trigger" || label == "fistPunch" || label == "fire" )
			{
				Display( battery.get( Display )).alpha = 1;
		
				timeline = getEntityById( WIRES ).get( Timeline );
				timeline.play();
				
				audio.playCurrentAction( TRIGGER );
				battery.remove( Interaction );
				ToolTipCreator.removeFromEntity( battery );
				
				shellApi.completeEvent( _events.SODA_PLACED + sodaPlacement );
			}
			
			else if( label == "ending" )
			{
				SceneUtil.setCameraTarget( this, getEntityById( CORE ));
		
				timeline = getEntityById( CORE_LASER + sodaPlacement ).get( Timeline );
				timeline.play();
				timeline.handleLabel( "shoot", Command.create( shootLaser, sodaPlacement ));
				
				timeline = player.get( Timeline );
				timeline.labelReached.removeAll();
			}
		}
		
		private function shootLaser( sodaPlacement:String ):void
		{
			// TOGGLE LASER FROM CORE
			var laser:Entity = getEntityById( CORE_LASER + sodaPlacement );
			var audio:Audio = laser.get( Audio );
			audio.playCurrentAction( TRIGGER );
			var timeline:Timeline;
			
			var coreWires:Entity;
			coreWires = ( crystalState == 3 ) ? getEntityById( CORE_WIRES + "front" ) : getEntityById( CORE_WIRES + "back" );
			audio = coreWires.get( Audio );
			audio.playCurrentAction( TRIGGER );
			
			timeline = coreWires.get( Timeline );
			timeline.play();
			
			var omegon:Entity = getEntityById( "omegon" );
			
			SceneUtil.addTimedEvent( this, new TimedEvent( 1, 1, Command.create( showOmegon, audio )));
			
			// UPDATE CORE TIMELINE
			timeline = getEntityById( CORE ).get( Timeline );
			timeline.play();
			
			if( crystalState == 3 )
			{
				audio = getEntityById( CORE ).get( Audio );
				audio.playCurrentAction( TRIGGER );
			}
			
			// UPDATE CORE SHAKE
			if( PlatformUtils.isDesktop )
			{
				var shakeMotion:ShakeMotion = getEntityById( CORE ).get( ShakeMotion );
				var shakeZone:EllipseZone = shakeMotion.shakeZone as EllipseZone;
				shakeZone.xRadius = shakeZone.yRadius = crystalState;
				
				// UPDATE THRONE SHAKE
				shakeMotion = getEntityById( THRONE ).get( ShakeMotion );
				shakeZone = shakeMotion.shakeZone as EllipseZone;
				shakeZone.xRadius = shakeZone.yRadius = crystalState;
			}
		}
		
		private function showOmegon( audio:Audio ):void
		{
			SceneUtil.setCameraTarget( this, getEntityById( "omegon" ));
			
			var dialog:Dialog = getEntityById( "omegon" ).get( Dialog );
			dialog.sayById( "wonder" + crystalState );
			dialog.complete.addOnce( assessCrystal );
			crystalState++;
			
			audio.stopActionAudio( TRIGGER );
		}
		
		private function critiqueCrystal( crystal:Entity ):void
		{
			CharUtils.setDirection( player, false );
		
			var dialog:Dialog = player.get( Dialog );
			
			var statement:String = ( shellApi.checkEvent( _events.CRYSTAL_READY_TO_BLOW )) ? "strike_back" : "needs_more_damage";
			dialog.sayById( statement );
		}
		
		private function assessCrystal( dialogData:DialogData ):void
		{
			SceneUtil.setCameraTarget( this, player );
			var dialog:Dialog = player.get( Dialog );
			var current:String = _events.SODA + ( crystalState - 1 );
			
			if( !shellApi.checkEvent( _events.CRYSTAL_READY_TO_BLOW ))
			{
				dialog.sayById( current );
				dialog.complete.addOnce( unlock );
			}
			else
			{
				CharUtils.setDirection( player, true );
				
				dialog.sayById( "strike_back" );
				dialog.complete.addOnce( unlock );
				removeEntity( getEntityById( "batteryClick" ));
				
				if( PlatformUtils.isDesktop )
				{
					crystalReady();
				}
			}
		}
		
		// READY TO BLOW THE CRYSTAL AND OMEGON
		private function crystalReady():void
		{
			var emitter2D:Emitter2D = new Emitter2D();
			var bitmapData:BitmapData = BitmapUtils.createBitmapData( new Droplet( 3 ));
			
			// DASH LINES PULLING IN	
			emitter2D.counter = new Random( 5, 10 );
			emitter2D.addInitializer( new BitmapImage( bitmapData, true, 20 ));
			emitter2D.addInitializer( new ColorInit( 0x00FF92, 0x3AA76F ));
			emitter2D.addInitializer( new Position( new EllipseZone( new Point( 0, 0 ), 25, 25 )));
			emitter2D.addInitializer( new Lifetime( .2 ));

			emitter2D.addInitializer( new Velocity( new EllipseZone( new Point( 0, 0 ), 300, 300 )));
			
			emitter2D.addAction( new MutualGravity( 1, 10, 1 ));
			emitter2D.addAction( new RotateToDirection());
			emitter2D.addAction( new Fade( .75, .55 ));			
			emitter2D.addAction( new ScaleImage( 1, .5 ));	
			emitter2D.addAction( new Age());
			emitter2D.addAction( new Move());
			
			EmitterCreator.create( this, _hitContainer, emitter2D, 275, 550, null, "shatterEmitter" );
		}
		
		
		/**
		 * DEFEAT OMEGON
		 */
		private function shatterCrystal( coreTarget:Entity ):void
		{
			var dialog:Dialog;
			
		
			if( shellApi.checkEvent( _events.CRYSTAL_READY_TO_BLOW ))
			{
				shellApi.completeEvent( _events.HIT_CRYSTAL );
				SceneUtil.setCameraPoint( this, 0, 0 );
				
				var sceneSound:Audio = AudioUtils.getAudio( this, SceneSound.SCENE_SOUND );
				sceneSound.stop( SoundManager.MUSIC_PATH + "reign_of_omegon.mp3" );
				AudioUtils.play( this, SoundManager.MUSIC_PATH + "wormhole_no_strings.mp3", 1, true );
				AudioUtils.play( this, SoundManager.EFFECTS_PATH + "electric_buzz_02a-02b.mp3", 1, true );
				
				CharUtils.moveToTarget( player, 1120, 720, true, explosionStarts );
				
				var omegon:Entity = getEntityById( "omegon" );
				dialog = omegon.get( Dialog );
				dialog.allowOverwrite = true;
				dialog.sayById( "what_was_that" );
				
				CharUtils.setAnim( getEntityById( "henchbot1" ), Stand, false, 0, 0, true );
				CharUtils.setAnim( getEntityById( "henchbot2" ), Stand, false, 0, 0, true );
				dialog.complete.addOnce( henchbotsToTheRescue );
			}
			else
			{
				dialog = player.get( Dialog );
				dialog.sayById( "needs_more_damage" );
				dialog.complete.addOnce( unlock );
			}
		}
		
		private function explosionStarts( player:Entity ):void
		{
			var display:Display = player.get( Display );
			display.alpha = 0;
		}
		
		private function henchbotsToTheRescue( dialogData:DialogData ):void
		{ 
			var dialog:Dialog = getEntityById( "henchbot1" ).get( Dialog );
			dialog.sayById( "no_idea" );
			dialog.complete.addOnce( crystalExplodes );
			
			CharUtils.moveToTarget( getEntityById( "henchbot1" ), 350, 340 );	
			CharUtils.moveToTarget( getEntityById( "henchbot2" ), 310, 340 );	
		}
		
		private function crystalExplodes( dialogData:DialogData ):void
		{				
			var lightOverlay:Entity = _portalGroup.lightOverlay;
			var display:Display = lightOverlay.get( Display );
			Sleep( lightOverlay.get( Sleep )).sleeping = false;
			
			var lightOverlaySprite:Sprite = new Sprite();
			lightOverlaySprite.mouseEnabled = false;
			lightOverlaySprite.mouseChildren = false;
			lightOverlaySprite.graphics.clear();
			lightOverlaySprite.graphics.beginFill( 0x00FF92, 1 );
			lightOverlaySprite.graphics.drawRect( 0, 0, super.shellApi.viewportWidth, super.shellApi.viewportHeight );
			overlayContainer.addChild( lightOverlaySprite );
			
			AudioUtils.play( this, SoundManager.EFFECTS_PATH + "glass_break_03.mp3", 2 );
			display = new Display( lightOverlaySprite );
			display.isStatic = true;
			display.alpha = 0;
			
			lightOverlay.add( display );
			
			SceneUtil.setCameraTarget( this, getEntityById( CORE ));
			// EXPLOSION PULSE
			var emitter2D:Emitter2D = new Emitter2D();
			emitter2D.counter = new Blast( 1 );
			emitter2D.addInitializer( new ImageClass( Ring, [ 10, 12, 0xffffff ], true, 1 ));
			emitter2D.addInitializer( new Position( new EllipseZone( new Point( 0, 0 ), 0, 0 )));
			emitter2D.addInitializer( new Lifetime( .25 ));
			
			emitter2D.addAction( new ScaleImage( .1, 40 ));	
			emitter2D.addAction( new Age());
			emitter2D.addAction( new Move());
			
			EmitterCreator.create( this, _hitContainer, emitter2D, 275, 550, null, "pulseEmitter" );
						
			var tween:Tween = new Tween();
			tween.to( display, 2, { alpha : 1, onComplete : explosionEnsues, onCompleteParams : [ lightOverlay ]});
			lightOverlay.add( tween );	
			
			AudioUtils.stop( this, SoundManager.EFFECTS_PATH + "electric_buzz_02a-02b.mp3" );
			AudioUtils.play( this, SoundManager.EFFECTS_PATH + "explosion_03.mp3", 2 );
			cameraShake();
		}
		
		private function cameraShake( on:Boolean = true ):void
		{
			if( PerformanceUtils.qualityLevel > PerformanceUtils.QUALITY_HIGH )
			{
				var cameraEntity:Entity = getEntityById("camera");
				if( on )
				{
					var waveMotion:WaveMotion = new WaveMotion();
					var waveMotionData:WaveMotionData = new WaveMotionData();
					waveMotionData.property = "y";
					waveMotionData.magnitude = 3;
					waveMotionData.rate = .5;
					waveMotionData.radians = 0;
					waveMotion.data.push(waveMotionData);
					cameraEntity.add(waveMotion);
					cameraEntity.add(new SpatialAddition());
				}
				else
				{
					cameraEntity.remove( WaveMotion );
					var spatialAddition:SpatialAddition = cameraEntity.get( SpatialAddition );
					spatialAddition.y = 0;
				}
			}
		}
		
		private function explosionEnsues( lightOverlay:Entity ):void
		{
			var display:Display = getEntityById( "after" ).get( Display );
			display.visible = true;
			Sleep( getEntityById( "after" ).get( Sleep )).sleeping= false;
			
			SceneUtil.setCameraPoint( this, 0, 0 );
			var entities:Vector.<Entity> = new <Entity>[ getEntityById( CORE ), getEntityById( WIRES ), getEntityById( CORE_LASER + "0" )
														, getEntityById( CORE_LASER + "1" ), getEntityById( CORE_LASER + "2" )
														, getEntityById( CORE_LASER + "3" ), getEntityById( "foreground" )
														, getEntityById( "henchbot1" ), getEntityById( "henchbot2" )
														, getEntityById( "meowbot" ), getEntityById( TAB_BLOCKER + "1" )
														, getEntityById( TAB_BLOCKER + "2" ), getEntityById( TAB_BLOCKER + "3" )
														, getEntityById( CORE_WIRES + "back" ), getEntityById( CORE_WIRES + "front" )
														, getEntityById( TAB + "1" ), getEntityById( TAB + "2" )
														, getEntityById( TAB + "3" ), getEntityById( "shatterEmitter" )
														, getEntityById( "force_shield" ), getEntityById( "force_field" )
														, getEntityById( THRONE ), getEntityById( "pulseEmitter" )];
			
			for each( var entity:Entity in entities )
			{
				removeEntity( entity );
			}
			
			display = lightOverlay.get( Display );
			var tween:Tween = lightOverlay.get( Tween );
			tween.to( display, 2.5, { alpha : 0, ease : Quadratic.easeOut, onComplete : endExplosion });

			_hitContainer.removeChild( _hitContainer[ "throne_cover" ]);
			display = getEntityById( "omegon" ).get( Display );
			display.alpha = 0;
		}
		
		private function endExplosion():void
		{
			var display:Display = player.get( Display );
			display.alpha = 1;
			
			cameraShake( false );
			
			// RECOLOR OVERLAY
			var lightOverlayEntity:Entity = getEntityById( "lightOverlay" );
			lightOverlayEntity.remove( Display );
			
			var lightOverlay:Sprite = new Sprite();
			lightOverlay.mouseEnabled = false;
			lightOverlay.mouseChildren = false;
			lightOverlay.graphics.clear();
			lightOverlay.graphics.beginFill( 0xFFFFFF, 1 );
			lightOverlay.graphics.drawRect( 0, 0, super.shellApi.viewportWidth, super.shellApi.viewportHeight );
			overlayContainer.addChild( lightOverlay );
			
			display = new Display( lightOverlay );
			display.isStatic = true;
			display.alpha = 0;
						
			lightOverlayEntity.add( display );
			var spatial:Spatial = player.get( Spatial );
			spatial.x = 1120;
			spatial.y = 720;
			
			CharUtils.followPath( player, new <Point>[ new Point( 950, 511 ), new Point( 670, 300 )], moveToThrone, true );
		}
		
		private function moveToThrone( player:Entity ):void
		{
			var motionControl:CharacterMotionControl = player.get( CharacterMotionControl );
			motionControl.runSpeed = 100;
			CharUtils.moveToTarget( player, 450, 330, true, mockOmegon );
		}
		
		private function mockOmegon( player:Entity ):void
		{
			var dialog:Dialog = player.get( Dialog );
			dialog.sayById( "banished_omegon" );
			dialog.complete.addOnce( proudMoment );
		}
		
		private function proudMoment( dialogData:DialogData ):void
		{
			CharUtils.setAnim( player, Proud );
			var timeline:Timeline = player.get( Timeline );
			timeline.handleLabel( "ending", foolishChild );
		}
		
		private function foolishChild():void
		{
			AudioUtils.play( this, SoundManager.EFFECTS_PATH + "robotic_evil_laugh_male_01.mp3" );
			var omegon:Entity = getEntityById( "omegon" );
			var spatial:Spatial = omegon.get( Spatial );
			var dialog:Dialog = omegon.get( Dialog );
			
			var portalSpatial:Spatial = _portalGroup.portal.get( Spatial );
			spatial.x = portalSpatial.x;
			spatial.y = portalSpatial.y;
			
			dialog.sayById( "foolish_child" );
			dialog.balloonPath = "ui/elements/wordBalloonRadio.swf";
			dialog.complete.addOnce( openPortal );
			
			CharUtils.setAnim( player, Tremble );
			// ADD OMEGON OPENING PORTAL
		}
		
		private function openPortal( dialogData:DialogData ):void
		{
			cameraShake();
			
			var dialog:Dialog = getEntityById( "omegon" ).get( Dialog );
			dialog.sayById( "my_power" );
			dialog.complete.addOnce( noMoreGames );
			
			AudioUtils.stop( this, SoundManager.MUSIC_PATH + "wormhole_no_strings" );
			AudioUtils.play( this, SoundManager.MUSIC_PATH + "ancient_power_awakens.mp3", 1, true );
		}
		
		private function noMoreGames( dialogData:DialogData ):void
		{
			cameraShake( false );
			
			_portalGroup.portalTransitionIn( startPull, portalClosed, _events.WEAPONS_POWERED_UP );
		}
		
		private function startPull( ...args ):void
		{
			CharUtils.setAnim( player, Grief );				
			var display:Display = player.get( Display );
			display.alpha = 0;
			
			var wrapper:BitmapWrapper =	super.convertToBitmapSprite( display.displayObject );
			var tween:Tween = new Tween();
			
			var spatial:Spatial = player.get( Spatial );
			wrapper.sprite.x = spatial.x;
			wrapper.sprite.y = spatial.y;
		
			var copy:Entity = EntityUtils.createMovingEntity( this, wrapper.sprite, display.container );
			copy.add( new Id( "playerCopy" ));
			spatial = copy.get( Spatial );
			tween.to( spatial, 2, { scaleX : spatial.scaleX * .5, scaleY : spatial.scaleY * .5 });
			
			spatial = _portalGroup.portal.get( Spatial );
			copy.add( new InwardSpiralComponent( new Point( spatial.x, spatial.y ), teleportCharacter )).add( tween );
		}
		
		private function teleportCharacter( character:Entity ):void
		{
			var display:Display = character.get( Display );
			var tween:Tween = new Tween();
			character.remove( InwardSpiralComponent );
			
			tween.to( display, .4, { alpha : 0, onComplete : playerThroughPortal });
			character.add( tween );
		}
		
		private function playerThroughPortal( ...args ):void
		{
			shellApi.completeEvent( _events.WEAPONS_POWERED_UP );
		}
		
		private function portalClosed():void
		{
			shellApi.loadScene( Portal );
		}
	
		
		private var _laserSequence:BitmapSequence;
		private var _wiresSequence:BitmapSequence;
		private var _coreWiresBackSequence:BitmapSequence;
		private var _coreWiresFrontSequence:BitmapSequence;
		private var _coreSequence:BitmapSequence;
		
		private var omegonIdle:Boolean = true;
		private var _portalGroup:PortalGroup;
		
		private var _box5Hit:Boolean 				= false;
		private var crystalState:Number 			= 1;
		private const BASIC_PULSE:Number			= 4;
		
		//  INTERACTIVE TIMELINES
		private const BATTERY:String				= "battery"; 		// 1-4
		private const LIFT:String					= "lift";			// 1-2
		private const LIFT_BASE:String 				= "lift_base";
		private const PANEL:String					= "panel";  		// 1-3, 1-2 on lifts
		private const TARGET:String					= "target";
		
		private const THRONE:String					= "throne";
		private const TAB:String					= "tab";
		private const TAB_BLOCKER:String			= "tab_blocker";
		
		//  RESPONSE TIMELINES
		private const CORE:String					= "core";   
		private const CORE_LASER:String				= "core_laser";		// 0-3	
		private const CORE_WIRES:String				= "core_wires_";
		private const WIRES:String					= "wires";
		
		private const TRIGGER:String			 	= "trigger";
	}
}
