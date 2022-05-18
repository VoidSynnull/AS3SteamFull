package game.scenes.viking.pen
{
	import com.poptropica.AppConfig;
	
	import flash.display.BitmapData;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.utils.Timer;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Motion;
	import engine.components.MotionBounds;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.Emitter;
	import game.components.animation.FSMControl;
	import game.components.entity.Dialog;
	import game.components.entity.Sleep;
	import game.components.entity.character.CharacterMotionControl;
	import game.components.entity.character.Npc;
	import game.components.entity.character.part.SkinPart;
	import game.components.entity.collider.BitmapCollider;
	import game.components.entity.collider.PlatformCollider;
	import game.components.entity.collider.SceneCollider;
	import game.components.entity.collider.ZoneCollider;
	import game.components.hit.CurrentHit;
	import game.components.hit.ValidHit;
	import game.components.motion.Destination;
	import game.components.motion.Edge;
	import game.components.motion.SceneObjectMotion;
	import game.components.motion.Threshold;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.BitmapSequence;
	import game.components.timeline.Timeline;
	import game.creators.entity.BitmapTimelineCreator;
	import game.creators.entity.EmitterCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.animation.entity.character.DuckDown;
	import game.data.animation.entity.character.DuckNinja;
	import game.data.animation.entity.character.Grief;
	import game.data.animation.entity.character.Laugh;
	import game.data.animation.entity.character.PointItem;
	import game.data.animation.entity.character.Proud;
	import game.data.animation.entity.character.SledgeHammer;
	import game.data.animation.entity.character.Throw;
	import game.data.character.LookData;
	import game.data.display.BitmapWrapper;
	import game.data.scene.characterDialog.DialogData;
	import game.data.scene.hit.HitAudioData;
	import game.scene.template.CharacterGroup;
	import game.scenes.viking.VikingScene;
	import game.scenes.viking.diningHall.DiningHall;
	import game.systems.entity.EyeSystem;
	import game.systems.entity.character.states.CharacterState;
	import game.systems.motion.ThresholdSystem;
	import game.util.AudioUtils;
	import game.util.BitmapUtils;
	import game.util.CharUtils;
	import game.util.DataUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.GeomUtils;
	import game.util.MotionUtils;
	import game.util.PerformanceUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.Fade;
	import org.flintparticles.common.actions.ScaleImage;
	import org.flintparticles.common.counters.Blast;
	import org.flintparticles.common.displayObjects.Blob;
	import org.flintparticles.common.initializers.BitmapImage;
	import org.flintparticles.common.initializers.ColorInit;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.RandomDrift;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.DiscZone;
	import org.flintparticles.twoD.zones.PointZone;
	
	public class Pen extends VikingScene
	{
		private var _mya:Entity;
		private var _oliver:Entity;
		private var _jorge:Entity;
		private var _octavian:Entity;
		private var _guard:Entity;
		private var _currentPig:Number = 1;
		
		private var PIG_VELOCITY_X:Number = -400;
		private var _guardTimer:TimedEvent;
		private var _teasing:Boolean = false;
		private var _laughing:Boolean = false;
		private var _characterGroup:CharacterGroup;
		
		private const PIG:String     = "pig";
		private const TRIGGER:String = "trigger";
		private const BREAK:String   = "break";
		private const OPEN:String  	 = "open";
		private const STEP:String	 = "step";
		
		public function Pen()
		{
			super();
		}
		
		override public function destroy():void 
		{
			if( _guardTimer )
			{
				_guardTimer.stop();
				_guardTimer = null;
			}
			super.destroy();
		}
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/viking/pen/";
			
			super.init(container);
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();
		}
		
		override protected function addBaseSystems():void
		{
			addSystem( new ThresholdSystem());
			super.addBaseSystems();
		}
		
		// all assets ready
		override public function loaded():void
		{
			super.loaded();
			
			_mya = getEntityById( "mya" );
			_oliver = getEntityById( "oliver" );
			_jorge = getEntityById( "jorge" );
			_guard = getEntityById( "guard" );
			_octavian = getEntityById( "octavian" );
			_characterGroup = CharacterGroup( getGroupById( CharacterGroup.GROUP_ID ));
			
			player.add( new ValidHit( "hayBale", "wood", "ground" ));
			_guard.add( new ValidHit( "hayBale", "wood", "ground", "guardPath" ));
			_octavian.add( new ValidHit( "hayBale", "wood", "ground" ));
			
			setupAssets();
		}
		
		private function setupAssets():void
		{
			var entity:Entity;
			var display:Display;
			var motionControl:CharacterMotionControl;
			var number:int;
			var sceneInteraction:SceneInteraction;
			var sequence:BitmapSequence;
			var spatial:Spatial;
			var timeline:Timeline;
			
			var bitmapClips:Vector.<MovieClip> = new <MovieClip>[ _hitContainer[ "pen" ]
																, _hitContainer[ "cage" ]
																, _hitContainer[ "hay" ]];
			
			var characters:Vector.<Entity> = new <Entity>[ _mya, _oliver, _jorge ];
			
			var timelineClips:Vector.<MovieClip> = new <MovieClip>[ _hitContainer[ "cageBlock" ]
																, _hitContainer[ "penBlock" ]];
			
			for( number = 0; number < timelineClips.length; number ++ )
			{
				sequence = BitmapTimelineCreator.createSequence( timelineClips[ number ], true, PerformanceUtils.defaultBitmapQuality );
				
				entity = makeEntity( timelineClips[ number ], sequence );
			}
			
			sequence = BitmapTimelineCreator.createSequence( _hitContainer[ PIG + number ], true, PerformanceUtils.defaultBitmapQuality );
			for( number = 1; number < 6; number ++ ) 
			{
				entity = makeEntity( _hitContainer[ PIG + number ], sequence );
			}
			
			timeline = getEntityById( "penBlock" ).get( Timeline );
			timeline.labelReached.add( penBlockHandler );
			
			entity.add( new AudioRange( 600 ));
			_audioGroup.addAudioToEntity( entity );
			
			for( number = 0; number < bitmapClips.length; number ++ )
			{
				makeEntity( bitmapClips[ number ]);
			}
			
			for each( entity in characters )
			{
				entity.add( new ValidHit( "cageGround", "ground" ));
				_characterGroup.addFSM( entity );
				_characterGroup.addAudio( entity );
				
				if( shellApi.checkItemEvent( _events.CANDYBAR ))
				{
					spatial = entity.get( Spatial );
					spatial.x -= 1200;
				}
				else
				{
					entity.remove( Npc );
					display = entity.get( Display );
					display.moveToBack();
				}
			}
			
			// create furs
			makeEntity( _hitContainer[ "furBack" ]);
			
			sequence = BitmapTimelineCreator.createSequence( _hitContainer[ "furPile" ], true, PerformanceUtils.defaultBitmapQuality );
			entity = makeEntity( _hitContainer[ "furPile" ], sequence );
			
			// create fur pile and equip helmet
			if( shellApi.checkEvent( _events.GAVE_FURS ))
			{
				equipFurs();
			}
			else
			{
				Display( entity.get( Display )).visible = false;
				Display( getEntityById( "furBack" ).get( Display )).visible = false;
			}
			
			if( shellApi.checkEvent( _events.GAVE_HELMET ))
			{
				SkinUtils.setSkinPart( _oliver, SkinUtils.HAIR, "comic_erik" );
			}
			
			addPigColliders( getEntityById( "pig1" ), true, false );
			// GUARD LOGIC
			_guard.remove( Npc );
			_characterGroup.addAudio( _guard );
			Dialog( _guard.get( Dialog )).faceSpeaker = false;
			
			sceneInteraction = _guard.get( SceneInteraction );
			sceneInteraction.reached.removeAll();
			sceneInteraction.reached.add( crossedGuard );
			
			_characterGroup.addFSM( _octavian );
			
			entity = getEntityById( "cageBlock" );
			if( shellApi.checkItemEvent( _events.CANDYBAR ))
			{
				timeline = entity.get( Timeline );
				timeline.gotoAndStop( "end" );
				display = entity.get( Display );
				
				display.displayObject.mouseChildren = false;
				display.displayObject.mouseEnabled = false;
			}
			else
			{
				_audioGroup.addAudioToEntity( entity );
				ToolTipCreator.addToEntity( entity );
				InteractionCreator.addToEntity( entity, [ InteractionCreator.CLICK ]);
				
				sceneInteraction = new SceneInteraction();
				sceneInteraction.reached.add( suchDoor );
				entity.add( sceneInteraction );
			}
			
			
			if( shellApi.checkEvent( _events.DONE_SPYING ))
			{
				removeEntity( _octavian );
				if( shellApi.checkEvent( _events.DRIPPINGS_FLUNG ))
				{
					removeEntity( _guard );
					for( number = 1; number < 6; number ++ )
					{
						removeEntity( getEntityById( PIG + number ));
					}
					
					entity = getEntityById( "penBlock" );
					timeline = entity.get( Timeline );
					timeline.gotoAndStop( "down" );
				}
				else
				{
					guardInPlace();
					
					_guardTimer = new TimedEvent( GeomUtils.randomInRange( 1, 3 ), 1, Command.create( tauntPig, _guard, false ))
					SceneUtil.addTimedEvent( this, _guardTimer );
				}
				
			}
			else
			{
				// reposition guard
			 	spatial = _guard.get( Spatial );
				spatial.x = -50;
				_guard.remove( Npc );
				
				Sleep( _guard.get( Sleep )).ignoreOffscreenSleep = true;
				Sleep( _octavian.get( Sleep )).ignoreOffscreenSleep = true;
				
				motionControl = player.get( CharacterMotionControl );
				motionControl.maxVelocityX = WALK_SPEED;
				
				SceneUtil.lockInput( this );
				CharUtils.moveToTarget( player, 700, 870, true, observeOctavian );
				
				_characterGroup.addAudio( _octavian );
			}
		}
		
		private function makeEntity( clip:MovieClip, sequence:BitmapSequence = null ):Entity
		{
			var entity:Entity;
			
			var sleep:Sleep;
			var timeline:Timeline;
			var wrapper:BitmapWrapper;
			
			if( sequence )
			{
				entity = EntityUtils.createSpatialEntity( this, clip );
				BitmapTimelineCreator.convertToBitmapTimeline( entity, clip, true, sequence, PerformanceUtils.defaultBitmapQuality );
				
				entity.add( new Id( clip.name ));
				entity.add( new AudioRange( 500 ));
				_audioGroup.addAudioToEntity( entity );
				
				if( clip.name.indexOf( PIG ) > -1 )
				{
					timeline = entity.get( Timeline );
					timeline.labelReached.add( Command.create( pigHandler, entity ));
					
					timeline.playing = clip.name == PIG + "1" ? true : false;
					
					sleep = new Sleep( false, true );
					sleep.sleeping = clip.name == PIG + "1" ? false : true;
					
					entity.add( sleep ).add( new AudioRange( 600 ));
					_audioGroup.addAudioToEntity( entity, clip.name );
					_characterGroup.addAudio( entity );
				}
			}
			else
			{
				if( PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_MEDIUM )
				{
					wrapper = DisplayUtils.convertToBitmapSprite( clip, null, PerformanceUtils.defaultBitmapQuality );
					entity = EntityUtils.createSpatialEntity( this, wrapper.sprite );
				}
				else
				{
					entity = EntityUtils.createSpatialEntity( this, clip );
				}
			}
			
			entity.add( new Id( clip.name ));
			return entity;
		}
		
		private function equipFurs():void
		{
			Spatial( getEntityById( "furBack" ).get( Spatial )).x = Spatial( _jorge.get( Spatial )).x;
			Spatial( getEntityById( "furPile" ).get( Spatial )).x = Spatial( _jorge.get( Spatial )).x;
			
			DisplayUtils.moveToOverUnder( Display( _jorge.get( Display )).displayObject, Display( getEntityById( "furPile" ).get( Display )).displayObject, false );
			DisplayUtils.moveToOverUnder( Display( _oliver.get( Display )).displayObject, Display( getEntityById( "furPile" ).get( Display )).displayObject, true );
			DisplayUtils.moveToTop(  Display( player.get( Display )).displayObject );
			
			Display( getEntityById( "furPile" ).get( Display )).visible = true;
			Display( getEntityById( "furBack" ).get( Display )).visible = true;
		}
		
		override protected function eventTriggered( event:String, makeCurrent:Boolean=true, init:Boolean=false, removeEvent:String=null ):void
		{
			var destination:Destination;
			var dialog:Dialog = player.get( Dialog );
			var playerSpatial:Spatial = player.get( Spatial );
			var fsmControl:FSMControl = player.get( FSMControl );
			var spatial:Spatial;
			var target:Point = new Point();
			
			switch( event )
			{
				case _events.HAND_MAP:
					SceneUtil.setCameraTarget( this, player, false, .02 );
					SkinUtils.setSkinPart( _oliver, SkinUtils.ITEM2, "newspaperrolled" );
					
					dialog.sayById( "notHim" );
					dialog.complete.addOnce( getReadyToHide );
					break;
			
				case _events.DRIPPINGS_USED:
					if( fsmControl.state.type == CharacterState.STAND )
					{
						if( !shellApi.checkEvent( _events.DRIPPINGS_FLUNG ))
						{
							SceneUtil.lockInput( this );
							SkinUtils.setSkinPart( player, SkinUtils.ITEM, "viking_bucket", true, positionForSlopThrow );
						}
						else
						{
							Dialog( player.get( Dialog )).sayById( "emptyBucket" );
						}
					}
					break;
				
				case _events.AXE_USED:
					if( fsmControl.state.type == CharacterState.STAND )
					{
						if( !shellApi.checkItemEvent( _events.CANDYBAR ))
						{
							if( shellApi.checkEvent( _events.PIGS_FREED ))
							{
								SkinUtils.setSkinPart( player, SkinUtils.ITEM, "comic_axe" );
								SceneUtil.lockInput( this );
								spatial = getEntityById( "cageBlock" ).get( Spatial );
								if( spatial.x < playerSpatial.x )
								{
									target.x = spatial.x - 80;
								}
								else
								{
									target.x = spatial.x - 50;
								} 
								
								CharUtils.moveToTarget( player, target.x, playerSpatial.y, true, positionedAtDoor );
							}
							else
							{
								dialog.sayById( "guard" );
							}
						}
						else
						{
							dialog.sayById( "nothingToChop" );
						}
					}
					break;
				
				case "vikingClothes":
					SceneUtil.lockInput( this, false );
					rushTheGates( _mya );
					rushTheGates( _oliver );
					rushTheGates( _jorge );
					break;
				
				/**
					case "triggerStampede":
						triggerStampede();
						break;
				*/
				case _events.USE_HELMET:
					if( shellApi.checkItemEvent( _events.CANDYBAR ))
					{
						if( !shellApi.checkEvent( _events.GAVE_HELMET ))
						{
							destination = CharUtils.moveToTarget( player, Spatial( _oliver.get( Spatial )).x, Spatial( _oliver.get( Spatial )).y, false, Command.create( putThisOn, _oliver ));
							destination.ignorePlatformTarget = true;
						}
					}
					else
					{
						if( shellApi.checkEvent( _events.PIGS_FREED ))
						{
							dialog.sayById( "gate" );	
						}
						else
						{
							dialog.sayById( "guard" );
						}
					}
					break;
				
				case _events.USE_FURS:
					if( shellApi.checkItemEvent( _events.CANDYBAR ))
					{
						if( !shellApi.checkEvent( _events.GAVE_FURS ))
						{
							destination = CharUtils.moveToTarget( player, Spatial( _jorge.get( Spatial )).x, Spatial( _jorge.get( Spatial )).y, false, Command.create( putThisOn, _jorge ));
							destination.ignorePlatformTarget = true;
						}
					}
					else
					{
						if( shellApi.checkEvent( _events.PIGS_FREED ))
						{
							dialog.sayById( "gate" );	
						}
						else
						{
							dialog.sayById( "guard" );
						}
					}
					break;
				
				default:
					break;
			}
			
			super.eventTriggered( event, makeCurrent, init, removeEvent );
		}
		
		private function turnFaceSpeakerOn( dialogData:DialogData ):void
		{
			var character:Entity = getEntityById( dialogData.entityID );
			Dialog( character.get( Dialog )).faceSpeaker = true;
		}
		
		// OCTAVIAN SEQUENCE 
		private function observeOctavian( player:Entity ):void
		{
			SceneUtil.setCameraTarget( this, _octavian, false, .02 );
			SceneUtil.addTimedEvent( this, new TimedEvent( 1, 1, begForMap ));
		}
		
		private function begForMap():void
		{
			var dialog:Dialog = _octavian.get( Dialog );
			dialog.faceSpeaker = false;
			dialog.sayById( "letMeSee" );
		}
			
		private function getReadyToHide( dialogData:DialogData ):void
		{
			SceneUtil.setCameraTarget( this, player, false, .2 );
			CharUtils.moveToTarget( player, 540, 850, true, hideBehindHay );
		}
		
		private function hideBehindHay( player:Entity ):void
		{
			var entity:Entity = getEntityById( "hay" );
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "grass_rustle_01.mp3");
			
			DisplayUtils.moveToOverUnder( player.get( Display ).displayObject, entity.get( Display ).displayObject, false );
			
			var hideableSpatial:Spatial = entity.get( Spatial );
			var playerSpatial:Spatial = player.get( Spatial );
			
			playerSpatial.x = hideableSpatial.x;
			playerSpatial.y = hideableSpatial.y;
			Display( player.get( Display )).visible = false
			
			CharUtils.setAnim( player, DuckDown );
			
			if( !shellApi.checkEvent( _events.DONE_SPYING ))
			{
				SceneUtil.setCameraTarget( this, _octavian, false, .02 );
				SceneUtil.addTimedEvent( this, new TimedEvent( 1.2, 1, giveMap ));
			}
		}
		
		private function unhide():void 
		{
			DisplayUtils.moveToTop( Display( player.get( Display )).displayObject );
			CharUtils.setState( player, CharacterState.STAND );
			CharUtils.lockControls( player, false, false );
			SceneUtil.lockInput( this, false );
			
			var hideableSpatial:Spatial = getEntityById( "hay" ).get( Spatial );
			var playerSpatial:Spatial = player.get( Spatial );
			
			playerSpatial.x = hideableSpatial.x;
			playerSpatial.y = hideableSpatial.y;
			
			Display( player.get( Display )).visible = true;
		}
		
		private function giveMap():void
		{
			var spatial:Spatial = _oliver.get( Spatial );
			SceneUtil.setCameraTarget( this, _octavian, false, .2 );
			CharUtils.moveToTarget( _octavian, spatial.x - 50, spatial.y + 100, true, takeMap );
			CharUtils.setAnim( _oliver, DuckNinja );
			
			var timeline:Timeline = _oliver.get( Timeline );
			timeline.handleLabel( TRIGGER, Command.create( animationHandler, _oliver ));
		}
		
		private function takeMap( octavian:Entity ):void
		{
			CharUtils.setDirection( _mya, true );
			CharUtils.setAnim( _octavian, PointItem );
			var timeline:Timeline = _octavian.get( Timeline );
			timeline.handleLabel( "pointing", Command.create( animationHandler, _octavian ));
		}
				
		private function tauntWithMap():void
		{
			CharUtils.setAnim( _octavian, Proud );
			var timeline:Timeline = _octavian.get( Timeline );
			timeline.handleLabel( "stand", correctEyes );
			
			var dialog:Dialog = _octavian.get( Dialog );
			dialog.sayById( "finally" );
			dialog.complete.add( characterGrief );
		}
		
		private function correctEyes():void
		{
			SkinUtils.setEyeStates( _octavian, EyeSystem.OPEN, EyeSystem.SQUINT );
			SkinUtils.setSkinPart( _oliver, SkinUtils.MOUTH, "sponsor_kk_bully03" );
		}
		
		private function octavianLaugh( dialogData:DialogData ):void 
		{
			CharUtils.setAnim( _octavian, Laugh );
		}
		
		private function characterGrief( dialogData:DialogData ):void
		{
			var dialog:Dialog;
			switch( dialogData.id )
			{
				case "finally":
					CharUtils.setAnim( _oliver, Grief );
					break;
				
				case "niceLife":
					CharUtils.setAnim( _jorge, Grief );
					CharUtils.setAnim( _mya, Grief );
					
					var lookData:LookData = SkinUtils.getLook( _octavian );
					lookData.setValue(SkinUtils.OVERSHIRT, "comic_underling" );
					lookData.setValue(SkinUtils.HAIR, "comic_octavian2" );
					
					SkinUtils.applyLook( _octavian, lookData, true, octavianInDisguise );
					break;
				
				default:
					break;
			}
		}
		
		private function octavianInDisguise( character:Entity ):void
		{
			CharUtils.setDirection( _mya, false );
			CharUtils.moveToTarget( _octavian, -50, 850, true, entityRanOffScreen );
		}
		
		// GUARD SEQUENCE
		private function enterGuard():void
		{
			var motionControl:CharacterMotionControl = new CharacterMotionControl();
			motionControl.maxVelocityX = WALK_SPEED;
			_guard.add( motionControl );
			var spatial:Spatial = _guard.get( Spatial );
			spatial.x = 0;
			spatial.y = 820;
			
			CharUtils.moveToTarget( _guard, 685, 890, true, tauntPig );
		}
		
		private function tauntPig( guard:Entity, firstTime:Boolean = true ):void
		{
			if( !shellApi.checkEvent( _events.GUARD_COVERED ))
			{
				CharUtils.setAnim( _guard, Throw );
				Timeline( _guard.get( Timeline )).handleLabel( "trigger", runSlopEmitter );
				_teasing = true;
					
				if( firstTime )
				{
					guardInPlace();
				}
			}
		}
		
		private function guardInPlace():void
		{
			var threshold:Threshold = new Threshold( "x", ">=", _guard );
			threshold.entered.add( crossedGuard );
			player.add( threshold );
			
			var motionControl:CharacterMotionControl = _guard.get( CharacterMotionControl );
			if( !motionControl )
			{
				motionControl = new CharacterMotionControl();
				_guard.add( motionControl );
			}
			
			motionControl.maxVelocityX = NORMAL_SPEED;
			
			motionControl = player.get( CharacterMotionControl );
			motionControl.maxVelocityX = NORMAL_SPEED;
		}
		
		private function crossedGuard( player:Entity = null, guard:Entity = null ):void
		{
			SceneUtil.lockInput( this );		
			
			var dialog:Dialog = _guard.get( Dialog );
			dialog.sayById( "cantPass" );
			dialog.complete.addOnce( moveBack );
		}
		
		private function moveBack( dialogData:DialogData ):void
		{
			var spatial:Spatial = _guard.get( Spatial );
			CharUtils.moveToTarget( player, spatial.x - 100, spatial.y, true, flipGuard );
		}
		
		private function flipGuard( player:Entity ):void
		{
			CharUtils.setDirection( _guard, true );
			CharUtils.setDirection( player, true );
			SceneUtil.lockInput( this, false );
			
			Dialog( player.get( Dialog )).sayById( "guard" );
		}
		
		private function doneTeasing( dialogData:DialogData ):void
		{
			if( !shellApi.checkEvent( _events.DONE_SPYING ))
			{
				shellApi.completeEvent( _events.DONE_SPYING );				
				unhide();
			}
			
			_laughing = false;
			_teasing = false;
			
			if( !shellApi.checkEvent( _events.GUARD_COVERED ))
			{
				_guardTimer = new TimedEvent( GeomUtils.randomInRange( 8, 12 ), 1, Command.create( tauntPig, _guard, false ))
				SceneUtil.addTimedEvent( this, _guardTimer );
			}
		}
		
		private function positionForSlopThrow( itemPart:SkinPart ):void
		{
			player.remove( Threshold );
			var spatial:Spatial = player.get( Spatial );
			var guardSpatial:Spatial = _guard.get( Spatial );
			
			var destination:Destination = CharUtils.moveToTarget( player, guardSpatial.x - 100, guardSpatial.y, true, throwSlop, new Point( 30, 30 ));
			destination.ignorePlatformTarget = true;
		}
		
		private function throwSlop( player:Entity ):void
		{
			CharUtils.setDirection( player, true );
			CharUtils.setAnim( player, Throw );
			SceneUtil.setCameraTarget( this, _guard );
			_teasing = true;
			
			var timeline:Timeline = player.get( Timeline );
			timeline.handleLabel( "trigger", Command.create( runSlopEmitter, true ));
			timeline.handleLabel( "ending", applySlop );
		}
		
		private function runSlopEmitter( isPlayer:Boolean = false ):void
		{
			var caster:Entity = isPlayer ? player : _guard;
			var id:Id = caster.get( Id );
			var spatial:Spatial = caster.get( Spatial );
			
			AudioUtils.play( this, SoundManager.EFFECTS_PATH + "sewage_impact_01.mp3" );
			
			var emitterEntity:Entity = getEntityById( "slopEmitter" + id.id  );
			if( !emitterEntity )
			{
				var emitter2D:Emitter2D = new Emitter2D();
				var bitmapData:BitmapData = BitmapUtils.createBitmapData( new Blob( 7 ));
				
				emitter2D = new Emitter2D();
				emitter2D.counter = new Blast( 20 );
				emitter2D.addInitializer( new BitmapImage( bitmapData ));
				emitter2D.addInitializer( new ColorInit( 0x705230, 0x54632E ));
				emitter2D.addInitializer( new Position( new DiscZone( new Point( 0, 0 ), 8, 1 )));
				emitter2D.addInitializer( new Lifetime( .5 ));
				
				emitter2D.addInitializer( new Velocity( new PointZone( new Point( 140, -430 )))); 
	
				emitter2D.addAction( new RandomDrift( 120, 333 ));
				emitter2D.addAction( new Fade( .75, 1 ));			
				emitter2D.addAction( new ScaleImage( 1, .5 ));		
				emitter2D.addAction( new Accelerate( 0, MotionUtils.GRAVITY ));
				emitter2D.addAction( new Age());
				emitter2D.addAction( new Move());
				
				EmitterCreator.create( this, _hitContainer, emitter2D, spatial.x + 20, spatial.y, null, "slopEmitter" + id.id );
			}
			else
			{
				var emitter:Emitter = emitterEntity.get( Emitter );
				emitter.emitter.start();
			}
		}
		
		private function applySlop():void
		{
			SkinUtils.setSkinPart( _guard, SkinUtils.MARKS, "comic_pigviking2" );
			SkinUtils.setSkinPart( _guard, SkinUtils.FACIAL, "comic_pigviking2" );
			SkinUtils.setSkinPart( _guard, SkinUtils.SHIRT, "comic_pigviking2", true, guardFreaksOut );
		}
		
		private function guardFreaksOut( skinPart:SkinPart ):void
		{
			SkinUtils.emptySkinPart( player, SkinUtils.ITEM );
			getReadyToHide( null );

			CharUtils.setAnim( _guard, Grief, false, 0, 0, true );
			
			shellApi.triggerEvent( _events.GUARD_COVERED, true );			
			var dialog:Dialog = _guard.get( Dialog );
			dialog.complete.removeAll();
			dialog.sayById( "whatTheDuece" );
			dialog.complete.addOnce( noticeFence );
		}
		
		private function noticeFence( dialogData:DialogData ):void
		{
			CharUtils.setDirection( _guard, true );
			SceneUtil.setCameraTarget( this, getEntityById( PIG + "1" ));
			
			var dialog:Dialog = _guard.get( Dialog );
			dialog.sayById( "notGood" );
			
			SceneUtil.addTimedEvent( this, new TimedEvent( 3, 1, triggerStampede ));
		}
		
		private function triggerStampede():void// dialogData:DialogData ):void
		{
			_currentPig ++;
			var pig:Entity = getEntityById( PIG + _currentPig );
			nextPigEscapes( pig );
			shellApi.completeEvent( _events.DRIPPINGS_FLUNG );
			
			var threshold:Threshold = new Threshold( "x", "<=" );
			threshold.entered.addOnce( forcePenOpen );
			threshold.threshold = 850;
			
			pig.add( threshold );
		}
		
		private function forcePenOpen( ...args ):void
		{
			if( !shellApi.checkEvent( _events.PIG_PEN_OPEN ))
			{
				shellApi.triggerEvent( _events.PIG_PEN_OPEN, true );
				this.shellApi.takePhoto("13480");
				
				var timeline:Timeline = getEntityById( "penBlock" ).get( Timeline );
				timeline.reverse = false;
				timeline.gotoAndPlay( "bust" );
				
				timeline = getEntityById( PIG + "1" ).get( Timeline );
				timeline.reverse = false;
				timeline.gotoAndPlay( "run" );
				addPigColliders( getEntityById( PIG + "1" ), false, true );
				
				var spatial:Spatial = _guard.get( Spatial );
				CharUtils.moveToTarget( _guard, -50, spatial.y, true, entityRanOffScreen );
				
				var audio:Audio = getEntityById( "penBlock" ).get( Audio );
				audio.playCurrentAction( BREAK );
			}
		}
		
		private function addPigColliders( pig:Entity, addColliders:Boolean = true, addMotion:Boolean = true ):void
		{		
			if( addMotion )
			{
				var motion:Motion	= new Motion();
				motion.friction 	= new Point( 0, 0 );
				motion.maxVelocity 	= new Point( 1000, 1000 );
				motion.minVelocity 	= new Point( 0, 0 );
				motion.acceleration = new Point( 0, MotionUtils.GRAVITY );
				motion.velocity.x 	= PIG_VELOCITY_X;
				motion.velocity.y 	= 0;
				
				pig.add( motion );
			}
			
			if( addColliders )
			{
				var sceneObjectMotion:SceneObjectMotion = new SceneObjectMotion();
				sceneObjectMotion.platformFriction = 0;
				sceneObjectMotion.rotateByVelocity = false;
				
				var threshold:Threshold = new Threshold( "x", "<=" );
				threshold.threshold = 0;
				threshold.entered.add( Command.create( entityRanOffScreen, pig ));
				
				pig.add( threshold );
				pig.add( new Edge( 50, 0, 50, 0 ));
				pig.add( new ValidHit( "guardPath", "penGround", "ground" ));
				pig.add( new BitmapCollider());
				pig.add( new SceneCollider());
				pig.add( new CurrentHit());
				pig.add( new ZoneCollider());
				pig.add( new MotionBounds( player.get( MotionBounds ).box ));
				pig.add( new PlatformCollider());
				pig.add( sceneObjectMotion );
			}
		}
		
		private function entityRanOffScreen( entity:Entity ):void
		{
			var id:Id = entity.get( Id );
			if( id.id == PIG + "5" )
			{
				SceneUtil.setCameraTarget( this, player );
				
				shellApi.triggerEvent( _events.PIGS_FREED, true );
				Audio( getEntityById( PIG + "2" ).get( Audio )).stopActionAudio( TRIGGER );
				unhide();
			}
			else if( entity == _octavian )
			{
				SceneUtil.setCameraTarget( this, player );
				enterGuard();
			}
			
			removeEntity( entity );
		}
		
		// CAGE LOGIC
		private function suchDoor( player:Entity, door:Entity ):void
		{
			Dialog( player.get( Dialog )).sayById( "suchDoor" );
		}
		
		private function positionedAtDoor( player:Entity ):void
		{
			CharUtils.setDirection( player, true );
			CharUtils.setAnim( player, SledgeHammer );
			
			SceneUtil.setCameraTarget( this, _oliver, true, .02 );
			
			var timeline:Timeline = player.get( Timeline );
			timeline.handleLabel( TRIGGER, Command.create( animationHandler, player ));
		}
		
		private function cageOpen():void
		{
			var cageDoor:Entity = getEntityById( "cageBlock" );
			var display:Display = cageDoor.get( Display );
			var timeline:Timeline = cageDoor.get( Timeline );
			timeline.gotoAndStop( "end" );
			
			ToolTipCreator.removeFromEntity( cageDoor );
			cageDoor.remove( SceneInteraction );
			cageDoor.remove( Interaction );
			
			CharUtils.moveToTarget( _mya, 1400, 800, true, exitCage );
			CharUtils.moveToTarget( _oliver, 1400, 800, true, exitCage );
			CharUtils.moveToTarget( _jorge, 1400, 800, true, exitCage );
			
			SceneUtil.setCameraTarget( this, player, true, .2 );
			
			SkinUtils.emptySkinPart( player, SkinUtils.ITEM );
			CharUtils.stateDrivenOn( player );
			
			display.displayObject.mouseChildren = false;
			display.displayObject.mouseEnabled = false;
		}
		
		private function exitCage( character:Entity ):void
		{
			character.remove( ValidHit );
			character.add( new ValidHit( "ground" )).add( new Npc());
			DisplayUtils.moveToOverUnder( Display( character.get( Display )).displayObject, Display( getEntityById( "cageBlock" ).get( Display )).displayObject );
			DisplayUtils.moveToOverUnder( Display( getEntityById( "cageBlock" ).get( Display )).displayObject, Display( getEntityById( "cage" ).get( Display )).displayObject );
			
			var spatial:Spatial = character.get( Spatial );
			
			switch( character )
			{
				case _jorge:
					CharUtils.moveToTarget( character, spatial.x - 200, spatial.y, true, faceRight );
					break;
				
				case _oliver:
					CharUtils.moveToTarget( character, spatial.x - 300, spatial.y, true, faceRight );
					break;
				
				case _mya:
					CharUtils.moveToTarget( character, spatial.x - 400, spatial.y, true, faceRight );
					break;
				
				default:
					break;
			}
		}
		
		private function faceRight( character:Entity ):void
		{
			CharUtils.setDirection( character, true );
			
			if( character == _jorge )
			{
				CharUtils.setDirection( player, false );
				Dialog( _jorge.get( Dialog )).sayById( "thankYou" );
			}
		}
		
		private function rushTheGates( character:Entity ):void
		{
			var spatial:Spatial = character.get( Spatial );
			CharUtils.moveToTarget( character, spatial.x - 700, spatial.y, true );
		}
		
		private function putThisOn( player:Entity, character:Entity ):void
		{
			if( character == _oliver )
			{
				SkinUtils.setSkinPart( _oliver, SkinUtils.HAIR, "comic_erik" );
				shellApi.triggerEvent( _events.GAVE_HELMET, true );
				shellApi.removeItem( _events.HELMET );
			}
			else
			{
				equipFurs();
				shellApi.triggerEvent( _events.GAVE_FURS, true );
				shellApi.removeItem( _events.FURS );
			}
			
			if( shellApi.checkEvent( _events.GAVE_FURS ) && shellApi.checkEvent( _events.GAVE_HELMET ))
			{
				shellApi.completeEvent( _events.BALANCE_GAME_STARTED );
				SceneUtil.lockInput( this, true );
				
				Dialog( _mya.get( Dialog )).sayById( "gave_furs" );
				Dialog( _mya.get( Dialog )).complete.addOnce( startBalanceGame );
			}
		}
		
		private function startBalanceGame( dialogData:DialogData ):void
		{
			shellApi.loadScene( DiningHall, 3500, 929, "left" );
		}
		
		// ANIMATION HANDLERS
		private function pigHandler( label:String, currentPig:Entity ):void
		{
			var audio:Audio;
			var currentHit:CurrentHit;
			var dialog:Dialog;
			var hitAudioData:HitAudioData;
			var id:Id = currentPig.get( Id );
			var motion:Motion;
			var pig:Entity = getEntityById( PIG + "1" );
			
			// ALL PIGS
			if( label.indexOf( STEP ) > -1 )
			{
				currentHit = currentPig.get( CurrentHit );
				if( currentHit && currentHit.hit )
				{
					hitAudioData = currentHit.hit.get( HitAudioData );
					
					audio = currentPig.get( Audio );
					audio.play( hitAudioData.currentActions[ STEP ].asset[ 0 ]);
				}
			}
			
			// ONLY PIG STARTING OUTSIDE
			if( id.id == PIG + "1" && !shellApi.checkEvent( _events.PIG_PEN_OPEN ))
			{
				var timeline:Timeline = pig.get( Timeline );
				var doorTimeline:Timeline = getEntityById( "penBlock" ).get( Timeline );
				
				if( label == "endIdle" )
				{
					if( !_teasing && !shellApi.checkEvent( _events.DRIPPINGS_FLUNG ))
					{
						timeline.gotoAndPlay( "idle" );
					}
				}
				
				if( label == TRIGGER )
				{
					doorTimeline.gotoAndPlay( label );
					audio = pig.get( Audio );
					audio.playCurrentAction( TRIGGER );
				}
				
				if( label == "endHappy" )
				{
					if( !shellApi.checkEvent( _events.DRIPPINGS_FLUNG ))
					{
						if( _teasing )
						{
							if( _laughing || shellApi.checkEvent( _events.GUARD_COVERED ))
							{
								timeline.gotoAndPlay( "teased" );
								doorTimeline.gotoAndPlay( "teased" );
							}
							else
							{
								_laughing = true;
								timeline.gotoAndPlay( "teased" );
								doorTimeline.gotoAndPlay( "teased" );
								CharUtils.setAnim( _guard, Laugh );
								dialog = _guard.get( Dialog );
								dialog.sayById( "heeHee" );
								dialog.complete.addOnce( doneTeasing );
							}
						}
						else
						{
							timeline.reverse = true;
							timeline.gotoAndPlay( "teased" );
							doorTimeline.reverse = true;				
							doorTimeline.gotoAndPlay( "teased" );
							timeline.handleLabel( "alerted", Command.create( backToIdle, pig ));
						}
					}
//					else
//					{
//						_currentPig ++;
//						nextPigEscapes( getEntityById( PIG + _currentPig ));
//					}
				}
				
				if( label == "bust" )
				{
					forcePenOpen();
					Audio( getEntityById( PIG + "2" ).get( Audio )).playCurrentAction( TRIGGER );
				}
			}
			
			// ONLY PIGS IN THE PEN
			else if( label == "releaseNextPig" )
			{
				var pigNumber:Number = DataUtils.getNumber( id.id.substr( 3 ));
				if( _currentPig == pigNumber )
				{
					_currentPig ++;
					
					if( _currentPig < 6 )
					{
						nextPigEscapes( getEntityById( PIG + _currentPig ));
					}
				}
			}
		}
		
		private function nextPigEscapes( pig:Entity ):void
		{
			pig.get( Sleep ).sleeping = false;
			
			var timeline:Timeline = pig.get( Timeline );
			timeline.gotoAndPlay( "run" );
			addPigColliders( pig );
		}
		
		private function backToIdle( pig:Entity ):void
		{
			var timeline:Timeline = pig.get( Timeline );
			timeline.reverse = false;
			
			timeline = getEntityById( "penBlock" ).get( Timeline );
			timeline.reverse = false;
		}
		
		private function resetSledge():void
		{
			CharUtils.setAnim( player, SledgeHammer );
			
			var timeline:Timeline = player.get( Timeline );
			timeline.handleLabel( TRIGGER, Command.create( animationHandler, player ));
		}
		
		private function animationHandler( character:Entity ):void
		{
			var audio:Audio;
			var timeline:Timeline;
			
			switch( character )
			{
				case _oliver:
					timeline = _oliver.get( Timeline );
					timeline.stop();
					break;
				
				case _octavian:
					timeline = _oliver.get( Timeline );
					timeline.play();
					SkinUtils.emptySkinPart( _oliver, SkinUtils.ITEM2 );	
					SkinUtils.setSkinPart( _octavian, SkinUtils.ITEM, "newspaperrolled", true );
					
					AudioUtils.play( this, SoundManager.EFFECTS_PATH + "paper_flap_02.mp3" );

					timeline = _octavian.get( Timeline );
					timeline.handleLabel( "ending", tauntWithMap );
					break;
				
				case player:
					audio = getEntityById( "cageBlock" ).get( Audio );
					
					timeline = getEntityById( "cageBlock" ).get( Timeline );
					
					if( timeline.data.getFrame( timeline.currentIndex ).label != "hitthreetimes" )
					{
						timeline.play();
						audio.playCurrentAction( TRIGGER );
						
						timeline = player.get( Timeline );
						timeline.handleLabel( "stopBreath", resetSledge );
					}
					else
					{					
						timeline.play();
						audio.playCurrentAction( BREAK );
						timeline.handleLabel( "end", cageOpen );
						timeline.handleLabel( "dooropen", Command.create( audio.playCurrentAction, OPEN ));
					}
					break;
				
				default:
					break;
			}
		}
		
		private function penBlockHandler( label:String ):void
		{
			var blocker:Entity = getEntityById( "penBlock" );
			var audio:Audio = blocker.get( Audio );
			
			if( label.indexOf( TRIGGER ) > -1 )
			{
				audio.playCurrentAction( TRIGGER );
			}
		}
	}
}