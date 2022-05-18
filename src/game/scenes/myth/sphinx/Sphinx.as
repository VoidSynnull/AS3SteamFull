package game.scenes.myth.sphinx
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
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
	import engine.components.Spatial;
	import engine.components.SpatialAddition;
	import engine.components.Tween;
	import engine.creators.InteractionCreator;
	import engine.util.Command;
	
	import fl.motion.easing.Quadratic;
	
	import game.components.Emitter;
	import game.components.entity.Dialog;
	import game.components.entity.Sleep;
	import game.components.hit.Door;
	import game.components.hit.Zone;
	import game.components.motion.Threshold;
	import game.components.motion.WaveMotion;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.BitmapSequence;
	import game.components.timeline.BitmapTimeline;
	import game.components.timeline.Timeline;
	import game.components.timeline.TimelineMaster;
	import game.components.ui.ToolTip;
	import game.creators.entity.BitmapTimelineCreator;
	import game.creators.entity.EmitterCreator;
	import game.creators.scene.HitCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.WaveMotionData;
	import game.data.animation.entity.character.Pull;
	import game.data.animation.entity.character.Push;
	import game.data.display.BitmapWrapper;
	import game.data.game.GameEvent;
	import game.data.scene.characterDialog.DialogData;
	import game.data.scene.hit.HitType;
	import game.scene.template.AudioGroup;
	import game.scenes.myth.shared.Athena;
	import game.scenes.myth.shared.MythScene;
	import game.scenes.myth.sphinx.components.BridgeComponent;
	import game.scenes.myth.sphinx.components.LeverComponent;
	import game.scenes.myth.sphinx.components.WaterWayComponent;
	import game.scenes.myth.sphinx.systems.AquaductSystem;
	import game.scenes.myth.sphinx.systems.BridgeSystem;
	import game.scenes.myth.sphinx.systems.WaterWaySystem;
	import game.systems.ParticleSystem;
	import game.systems.SystemPriorities;
	import game.systems.entity.character.states.CharacterState;
	import game.systems.motion.ThresholdSystem;
	import game.systems.motion.WaveMotionSystem;
	import game.systems.timeline.TimelineVariableSystem;
	import game.ui.showItem.ShowItem;
	import game.util.BitmapUtils;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.PerformanceUtils;
	import game.util.PlatformUtils;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.Fade;
	import org.flintparticles.common.actions.ScaleImage;
	import org.flintparticles.common.counters.Steady;
	import org.flintparticles.common.displayObjects.Blob;
	import org.flintparticles.common.easing.Quadratic;
	import org.flintparticles.common.initializers.AlphaInit;
	import org.flintparticles.common.initializers.BitmapImage;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Rotation;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.EllipseZone;
	import org.flintparticles.twoD.zones.LineZone;
	
	public class Sphinx extends MythScene
	{
		//		private var _audioGroup:AudioGroup;
		
		public function Sphinx()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/myth/sphinx/";
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
			super.loaded();
			_openAthena = false;
			
			_audioGroup.addAudioToEntity( getEntityById( "sphinx" ));
			
			super.shellApi.eventTriggered.add( eventTriggers );	
			addSystem( new WaveMotionSystem() );
			addSystem( new ThresholdSystem() );
			addSystem( new TimelineVariableSystem() );
			
			super.addSystem(new ParticleSystem(), SystemPriorities.update);
			
			_bitmapQuality = ( PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_LOW ) ? .5 : 1;
			_flooded = super.shellApi.checkEvent( _events.SPHINX_FLOODED );
			
			// need to save the event for door checking after the transition, remove it next time you enter
			// the scene
			if( shellApi.checkEvent( _events.LABYRINTH_OPEN ))
			{
				shellApi.removeEvent( _events.LABYRINTH_OPEN );
			}

			setupFlower();
			setupWaterFallRipples();
			
			var sceneInteraction:SceneInteraction;
			var entity:Entity;
			if( !_flooded )
			{
				if( super.shellApi.checkEvent( _events.SPHINX_AWAKE ))
				{
					super.shellApi.removeEvent( _events.SPHINX_AWAKE );
				}
				
				// deactivate flooded water
				entity = getEntityById( "floodedBackground" );
				EntityUtils.visible( entity, false, true );
				entity.add( new Sleep( true, true ));
				
				getEntityById( "waterHit" ).add( new Sleep( true, true ));
				
				getEntityById( "floodedForeground" ).add( new Sleep( true, true ));
				EntityUtils.visible( entity, false, true );
				Display( entity.get( Display )).visible = false;
			}		
			else
			{
				super.removeEntity( super.getEntityById( "dirt" ));

				wakeSphinx();
				_awake = true;
			}	
			
			labyrinthDoor();
			setupOlive();
			setupAquaduct();
			setupZees();
		}
		
		override protected function addCharacterDialog( container:Sprite ):void
		{
			setupSphinx( _flooded );
			super.addCharacterDialog( container );
		}
		
		
		private function setupFlower():void
		{
			if( shellApi.checkEvent( GameEvent.HAS_ITEM + _events.SPHINX_FLOWER ))
			{
				_hitContainer.removeChild( _hitContainer["flowerSparkle"] );
				_hitContainer.removeChild( _hitContainer["flower"] );
				_hitContainer.removeChild( _hitContainer["flowerTarget"] );
			}
			else
			{
				// create sparkle
				var clip:MovieClip = _hitContainer["flowerSparkle"];
				clip.visible = false;
				var flowerSparkleEntity:Entity = EntityUtils.createSpatialEntity( this, clip );
				flowerSparkleEntity.add( new Id( "flowerSparkle" ));
				flowerSparkleEntity.add(new Sleep());
				TimelineUtils.convertClip( clip, this, flowerSparkleEntity );
				if( !_flooded )
				{
					var spatial:Spatial = flowerSparkleEntity.get( Spatial );
					spatial.x += 30;
					spatial.y -= 50;
				}
				
				// create flower
				var entity:Entity = EntityUtils.createSpatialEntity( this, _hitContainer[ "flower" ]);
				entity.add( new Id( "flower" ));
				if(!PlatformUtils.isDesktop)
				{
					DisplayUtils.bitmapDisplayComponent(entity, true, _bitmapQuality);
				}
				Display( entity.get( Display )).visible = _flooded;
				
				// create flower hit
				entity = EntityUtils.createSpatialEntity( this, _hitContainer[ "flowerTarget" ]);
				ToolTipCreator.addToEntity( entity );
				InteractionCreator.addToEntity( entity, [ InteractionCreator.CLICK ]);
				var sceneInteraction:SceneInteraction = new SceneInteraction();
				sceneInteraction.reached.removeAll();
				sceneInteraction.reached.add( getFlower );
				entity.add( sceneInteraction ).add( new Id( "flowerTarget" ));
			}
		}
		
		/**
		 * Create ripple effect for lower waterfalls, shown once aqueduct is complete.
		 * 
		 */
		private function setupWaterFallRipples():void
		{
			var ripplesClip:MovieClip = _hitContainer[ "ripples" ] as MovieClip;
			var ripplesEntity:Entity = new Entity();
			ripplesEntity.add( new Spatial( ripplesClip.x, ripplesClip.y ) );
			ripplesEntity.add( new Id( "ripples" ));
			ripplesEntity.add( new AudioRange( 600, .02, 2 ));	// only add a single audio to the last entity
			_audioGroup.addAudioToEntity( ripplesEntity );
			EntityUtils.visible( ripplesEntity, _flooded );
			ripplesEntity.add( new Sleep( true, !_flooded) );
			super.addEntity( ripplesEntity );

			var numFalls:int = 6;
			var clip:MovieClip;
			var bitmapWrapper:BitmapWrapper;
			var rippleEntity:Entity;
			for (var i:int = 0; i < numFalls; i++) 
			{
				clip = ripplesClip[ "ripple_" + i ] as MovieClip;
				if( PerformanceUtils.qualityLevel > PerformanceUtils.QUALITY_LOW )	// if high performance convert into bitmap animations
				{
					rippleEntity = EntityUtils.createSpatialEntity( this, clip);
					rippleEntity.add( new Id( "ripple_" + i ));
					rippleEntity.add( new Sleep(true, !_flooded) );
					BitmapTimelineCreator.convertToBitmapTimeline( rippleEntity, clip, true, null, _bitmapQuality, 96 );
					var display:Display = Display( rippleEntity.get( Display ));
					display.visible = _flooded;
					Timeline(rippleEntity.get(Timeline)).playing = _flooded;
					EntityUtils.addParentChild( rippleEntity, ripplesEntity );
				}
				else																// if low performacne convert to static bitmaps
				{
					clip.stop();
					bitmapWrapper = super.convertToBitmapSprite( clip, null, true, _bitmapQuality );
					bitmapWrapper.sprite.visible = _flooded;
				}
			}
		}
		
		// process incoming events
		private function eventTriggers( event:String, save:Boolean = true, init:Boolean = false, removeEvent:String = null ):void
		{
			var spatial:Spatial;
			var dialog:Dialog;
			var audio:Audio;
			
			switch( event )
			{
				case _events.DOOR_JAM:
					spatial = player.get( Spatial );
					dialog = player.get( Dialog );
					
					var inTheX:Boolean = false;
					var inTheY:Boolean = false;
					
					if( spatial.x > 260 && spatial.x < 815 )
					{
						inTheX = true;
					}
					
					if( spatial.y > 1500 && spatial.y < 2050 )
					{
						inTheY = true;
					}
					
					if( inTheX && inTheY )
					{
						shellApi.triggerEvent( _events.LABYRINTH_OPEN, true );
					}
						
					else
					{
						dialog.sayById( "no_effect" );		
					}
					break;
				
				case _events.LABYRINTH_OPEN:
					SceneUtil.addTimedEvent( this, new TimedEvent( .2, 1, openGate ));
					audio = getEntityById( "labyrinthGate" ).get( Audio );
					audio.playCurrentAction( TRIGGER );
					//super.shellApi.triggerEvent( "door_open" );
					break;
				
				case _events.AQUADUCT_COMPLETE:
					if( !super.shellApi.checkEvent( _events.SPHINX_FLOODED ))
					{
						floodBackground();
						super.removeEntity( super.getEntityById( "dirt" ));
						//super.removeEntity( super.getEntityById( "unfloodedWalls" ));
					}
					break;
				
				case _events.SPHINX_AWAKE:
					wakeSphinx();
					break;
			}
		}
		
		private function wakeSphinx( byFlower:Boolean = false ):void
		{
			var entity:Entity;
			var timeline:Timeline;
			var number:int;
			var display:Display;
			
			var wave:WaveMotion = new WaveMotion();
			var waveData:WaveMotionData = new WaveMotionData( "y", 6, .01 );
			var threshold:Threshold = new Threshold( "x", "<" );
			threshold.threshold = 1250;
			threshold.entered.addOnce( turnHead );
			player.add( threshold );
			
			wave.data.push( waveData );
			waveData = new WaveMotionData( "x", 8, .05 );
			wave.data.push( waveData );
			waveData = new WaveMotionData( "rotation", 4, .02 );
			wave.data.push( waveData );
			
			entity = super.getEntityById( "eyes" );
			timeline = entity.get( Timeline );
			timeline.gotoAndStop( "awake" );
			
			entity = super.getEntityById( "mouth" );
			timeline = entity.get( Timeline );
			
			if( !byFlower )
			{
				timeline.gotoAndStop( "awake" );
			}
			else
			{
				timeline.gotoAndPlay( "talk" );
			}
			
			for( number = 1; number < 11; number ++ )
			{
				entity = getEntityById( "z" + number );
				if( entity )
				{
					super.removeEntity( entity );
				}
			}
			
			entity = super.getEntityById( "sphinx" );
			entity.add( wave ).add( new SpatialAddition());
			
			_awake = true;
		}
		
		/*******************************
		 * 		     ATHENA
		 * *****************************/
		private function setupOlive():void
		{
			var entity:Entity;
			entity = getEntityById( "oliveInteraction" );
			//			var sceneInteraction:SceneInteraction = entity.get( SceneInteraction );
			//			sceneInteraction.offsetX = 100;
			//			sceneInteraction.offsetY = 100;
			entity.remove( SceneInteraction );
			Interaction( entity.get( Interaction )).click.add( athenaPopup );
		}
		
		private function athenaPopup( interactionEntity:Entity ):void
		{
			if( !_openAthena )
			{
				_openAthena = true;
				var popup:Athena = super.addChildGroup( new Athena( super.overlayContainer )) as Athena;
				popup.closeClicked.add( resetPopup );
				popup.id = "athena";
			}
		}
		
		private function resetPopup( ...args ):void
		{
			_openAthena = false;
		}
		
		/*******************************
		 * 		    LABYRINTH
		 * *****************************/
		private function labyrinthDoor():void
		{
			var entity:Entity; 
			var sceneInteraction:SceneInteraction;
			var zone:Zone;
			
			entity = getEntityById( "labyrinthDoor" );
			Door( entity.get( Door )).open = false;
			sceneInteraction = entity.get( SceneInteraction );
			sceneInteraction.reached.removeAll();
			sceneInteraction.reached.add( doorReached );
			
			entity = EntityUtils.createSpatialEntity( this, _hitContainer[ "labyrinthGate" ]);
			if(!PlatformUtils.isDesktop){
				DisplayUtils.bitmapDisplayComponent(entity,true,_bitmapQuality * 2);	// increase bitmap quality for reabability
			}
			entity.add( new Id( "labyrinthGate" ));
			_audioGroup.addAudioToEntity( entity );
			
			BitmapUtils.convertContainer(_hitContainer[ "gateTop" ],_bitmapQuality);
			// TODO :: Not sure why labyrinthGate is getting move up in layering? - bard
			//DisplayUtils.moveToOverUnder( _hitContainer[ "gateTop" ], _hitContainer[ "labyrinthGate" ] );
		}
		
		private function openGate():void
		{
			var entity:Entity;
			var spatial:Spatial;
			var tween:Tween;
			
			SceneUtil.lockInput( this );
			
			entity = getEntityById( "labyrinthGate" );
			spatial = entity.get( Spatial );
			tween = new Tween();
			
			tween.to( spatial, 2, { y : 1888, ease : fl.motion.easing.Quadratic.easeInOut, onComplete : labyrinthOpen });
			entity.add( tween );
		}
		
		private function labyrinthOpen():void
		{
			var entity:Entity;
			entity = getEntityById( "labyrinthDoor" );
			// enable door
			SceneInteraction( entity.get( SceneInteraction )).reached.add( doorReached );		
			unlockInput();
		}
		
		private function unlockInput( dialogData:DialogData=null ):void
		{
			SceneUtil.setCameraTarget( this, player );
			SceneUtil.lockInput( this, false );
		}
		
		private function doorReached( char:Entity, door:Entity ):void
		{
			SceneUtil.lockInput( this );
			
			if( shellApi.checkEvent( _events.LABYRINTH_OPEN ))
			{
				// open
				Door( door.get( Door )).open = true;
			}
			else
			{
				// not open
				Dialog( char.get( Dialog )).sayById( "door_locked" );
				Dialog( char.get( Dialog )).complete.add( unlockInput );
			}
		}
		
		
		/*******************************
		 * 			SPHINX
		 * *****************************/
		private function setupSphinx( flooded:Boolean ):void
		{
			var entity:Entity;
			var timeline:Timeline;
			var state:String;
			var eyes:Entity;
			var mouth:Entity;
			
			if( flooded )
			{
				state = "awake";
			}
			else
			{
				state = "sleep";
			}
			
			entity = EntityUtils.createSpatialEntity( this, _hitContainer[ "head" ]);
			entity.add( new Id( "sphinx" ));
			var dialog:Dialog = new Dialog();
			dialog.dialogPositionPercents = new Point(0, .5);			
			dialog.faceSpeaker = false;
			entity.add(dialog);
			
			eyes = TimelineUtils.convertClip( MovieClip( MovieClip( EntityUtils.getDisplayObject( entity )).getChildByName("eyes")), this, null, entity);
			eyes.add( new Id( "eyes" ));
			timeline = eyes.get( Timeline );
			timeline.gotoAndStop( state );
			
			mouth = TimelineUtils.convertClip( MovieClip( MovieClip( EntityUtils.getDisplayObject( entity )).getChildByName("mouth")), this, null, entity);
			mouth.add( new Id( "mouth" ));
			timeline = mouth.get( Timeline );
			timeline.gotoAndStop( state );
		}
		
		private function turnHead( left:Boolean = true ):void
		{
			var entity:Entity = super.getEntityById( "sphinx" );
			
			var threshold:Threshold = player.get( Threshold );
			threshold.entered.removeAll();
			
			if( left )
			{
				Spatial( entity.get( Spatial )).scaleX = -1;
				threshold.operator = ">";
				threshold.entered.add( Command.create( turnHead, false ));
			}
			else
			{
				Spatial( entity.get( Spatial )).scaleX = 1;
				threshold.operator = "<";
				threshold.entered.add( turnHead );
			}
		}
		
		/*******************************
		 * 			AQUADUCT
		 * *****************************/
		private function setupAquaduct():void
		{
			var clip:MovieClip;
			var entity:Entity;
			var lever:LeverComponent;
			var number:Number;

			var startLeft:Boolean;
			var leftAlt:Boolean;
			var waterWay:WaterWayComponent;
			var bridge:BridgeComponent;
			var sceneInteraction:SceneInteraction;
			var audio:Audio;
			var spatial:Spatial;
			
			
			// create top waterfall
			entity = EntityUtils.createSpatialEntity( this, _hitContainer[ "aquafall" ]);
			BitmapTimelineCreator.convertToBitmapTimeline( entity, _hitContainer[ "aquafall" ], true, null, _bitmapQuality, 96 );
			Timeline(entity.get(Timeline)).playing = true;
			entity.add( new Id( "waterfall" ))
			entity.add( new AudioRange( 200, 0.01, 1 ));
			entity.add( new Sleep(true, false) );
			_audioGroup.addAudioToEntity( entity );
			audio = entity.get( Audio );
			audio.playCurrentAction( TRIGGER )
			
			// WATERWAYS
			var flowSourceClip:MovieClip = _hitContainer["flowSource"];
			flowSourceClip.gotoAndStop(1);
			var bitmapSequence:BitmapSequence = BitmapTimelineCreator.createSequence(flowSourceClip, false);
			_hitContainer.removeChild( flowSourceClip );

			var wayClip:MovieClip;
			var wayEntity:Entity;
			var wayChildClip:MovieClip;
			var wayChildEntity:Entity;
			var spriteContainer:Sprite;
			var bitmapContainer:Bitmap;
			var timeline:Timeline;
			for( number = 0; number < 10; number ++ )
			{
				wayClip = _hitContainer[ "way" + number ];
				wayEntity = EntityUtils.createSpatialEntity( this, wayClip);
				waterWay = new WaterWayComponent();
				wayEntity.add( waterWay );
				wayEntity.add( new Id( "way" + number ) );
				wayEntity.add( new AudioRange( 200, 0.01, 1 ) );
				_audioGroup.addAudioToEntity( wayEntity );
				timeline = new Timeline();
				TimelineUtils.parseMovieClip( timeline, flowSourceClip );
				wayEntity.add( timeline );
				wayEntity.add( new TimelineMaster() );
				wayEntity.add( new Sleep( true, false ) );
				//wayEntity.add( new TimelineMasterVariable( 64 ) );	// if we want to slow down playback
				
				for (var j:int = 0; j < wayClip.numChildren ; j++) 
				{
					wayChildClip = wayClip["f"+j];
					wayChildEntity = EntityUtils.createSpatialEntity(this, wayChildClip);
					var display:Display = wayChildEntity.get(Display);
					
					// create bitmap timeline
					display.displayObject.gotoAndStop(1);
					wayChildEntity.add( timeline );
					
					wayChildEntity.add( bitmapSequence );
					
					// create sprite container
					spriteContainer = new MovieClip();
					spriteContainer.mouseChildren = false;
					spriteContainer.mouseEnabled = false;
					bitmapContainer = new Bitmap( null, "auto", true );
					
					spriteContainer.addChild( bitmapContainer );
					spriteContainer.name = display.displayObject.name;
					spriteContainer.transform.matrix = wayChildClip.transform.matrix;
					display.displayObject = DisplayUtils.swap( spriteContainer, display.displayObject );
					
					wayChildEntity.add( new Sleep(true, false) );
					wayChildEntity.add( new BitmapTimeline( bitmapContainer ) );	
					EntityUtils.addParentChild( wayChildEntity, wayEntity );
				}
				timeline.reset(true);			

				if( number == 0 )
				{
					waterWay.isOn = true;
					audio = wayEntity.get( Audio );
					audio.playCurrentAction( TRIGGER );
					//	audio.play( SoundManager.EFFECTS_PATH + FLOW, true, SoundModifier.POSITION );
				}
			}
			
			// BRIDGES 
			for( number = 0; number < 2; number ++ )
			{
				bridge = new BridgeComponent();
				// bridges
				clip = _hitContainer[ "bridge" + number ];
				entity = EntityUtils.createSpatialEntity( this, clip);
				entity.add( new Id( "bridge" + number ));
				spatial = entity.get( Spatial );
				if(!PlatformUtils.isDesktop)
				{
					DisplayUtils.bitmapDisplayComponent(entity,true,_bitmapQuality);
				}
				//audioGroup.addAudioToEntity( entity );
				
				// bridge platforms
				entity = EntityUtils.createSpatialEntity( this, _hitContainer[ "bridgePath" + number ]);
				entity.add( new Id( "bridgePath" + number ));
				var hitCreator:HitCreator = new HitCreator();
				hitCreator.addHitSoundsToEntity( entity, _audioGroup.audioData, shellApi );
				
				// bridge hits
				entity = EntityUtils.createSpatialEntity( this, _hitContainer[ "bridgeTarget" + number ]);
				entity.add( new Id( "bridgeTarget" + number )).add( new AudioRange( 200, 0.01, 1 ));
				_audioGroup.addAudioToEntity( entity );
				
				ToolTipCreator.addToEntity( entity );
				
				bridge.displayEntity = getEntityById( "bridge" + number );
				bridge.pathEntity = getEntityById( "bridgePath" + number );
				
				bridge.fallRotation = 101;
				bridge.reboundOne = 50;
				bridge.reboundTwo = 90;
				
				switch( number )
				{
					case 0:
						bridge.pathIn = getEntityById( "way4" ).get( WaterWayComponent );
						bridge.feedsInto = getEntityById( "way5" ).get( WaterWayComponent );
						bridge.fallRotation *= -1;
						bridge.reboundOne *= -1;
						bridge.reboundTwo *= -1;
						break;
					case 1:
						bridge.pathIn = getEntityById( "way7" ).get( WaterWayComponent );
						bridge.feedsInto = getEntityById( "way8" ).get( WaterWayComponent );
						break;
				}
				
				entity.add( bridge ).add( new Tween());
				
				if( shellApi.checkEvent( _events.SPHINX_FLOODED ))
				{
					var creator:HitCreator = new HitCreator();
					var platform:Entity = bridge.pathEntity;
					
					creator.makeHit( platform, HitType.PLATFORM );
					thirdFall( entity );
				}
					
				else
				{
					InteractionCreator.addToEntity( entity, [ InteractionCreator.CLICK ]);
					sceneInteraction = new SceneInteraction();
					sceneInteraction.validCharStates = new <String>[ CharacterState.STAND, CharacterState.WALK ]; 
					entity.add( sceneInteraction );	
					sceneInteraction.reached.addOnce( pushBridge );
					sceneInteraction.minTargetDelta.x = 30;
					sceneInteraction.offsetX = 40;
				}
			}
			// BRIDGE BRACES
			for( number = 0; number < 4; number ++ )
			{
				clip = _hitContainer[ "brace" + number ];
				if(!PlatformUtils.isDesktop){
					BitmapUtils.convertContainer(clip, _bitmapQuality);
				}
			}
			
			// LEVERS & WATERFALLS
			var fallSourceClip:MovieClip = _hitContainer["fallSource"];
			fallSourceClip.gotoAndStop(1);
			var fallBitmapSequence:BitmapSequence = BitmapTimelineCreator.createSequence(fallSourceClip,true,1);
			_hitContainer.removeChild( fallSourceClip );
			
			var levelBitmapData:BitmapData;
			for( number = 0; number < 4; number ++ )
			{
				startLeft = false;
				leftAlt = true;
				
				switch( number )
				{
					case 0:
						startLeft = true;
						if( shellApi.checkEvent( _events.SPHINX_FLOODED ))
						{
							startLeft = false;
						}
						break;
					case 1:
						leftAlt = false;
						if( shellApi.checkEvent( _events.SPHINX_FLOODED ))
						{
							startLeft = true;
						}
						break;
					case 2:
						startLeft = true;
						if( shellApi.checkEvent( _events.SPHINX_FLOODED ))
						{
							startLeft = false;
						}
						break;
					case 3: 
						leftAlt = false;
						if( shellApi.checkEvent( _events.SPHINX_FLOODED ))
						{
							startLeft = true;
						}
						break;
				}
				
				lever = new LeverComponent ( startLeft, leftAlt );
				clip = _hitContainer[ "lever" + number ];
				entity = EntityUtils.createSpatialEntity( this, clip ); 
				entity.add( new Id( "lever" + number )).add( lever );
				_audioGroup.addAudioToEntity( entity );
				
				if(!PlatformUtils.isDesktop)
				{
					DisplayUtils.bitmapDisplayComponent(entity,true,_bitmapQuality);	// increase quality for rotation
				}
				
				if( startLeft )
				{
					Spatial( entity.get( Spatial )).rotation = MIN_THETA;
				}
				else
				{
					Spatial( entity.get( Spatial )).rotation = MAX_THETA;
				}
				
				ToolTipCreator.addToEntity( entity );
				InteractionCreator.addToEntity( entity, [ InteractionCreator.CLICK ]);
				sceneInteraction = new SceneInteraction();
				sceneInteraction.validCharStates = new <String>[ CharacterState.STAND, CharacterState.WALK]; 
				sceneInteraction.minTargetDelta.x = 30;
				sceneInteraction.minTargetDelta.y = 120;
				entity.add( sceneInteraction );	
				sceneInteraction.reached.add( moveLever );
				
				// create aqueduct waterfalls
				waterWay = new WaterWayComponent();
				waterWay.isFall = true;
				entity = EntityUtils.createSpatialEntity( this, _hitContainer[ "fall" + number ]);
				entity.add( new Id( "fall" + number ))
				entity.add( waterWay )
				entity.add( new AudioRange( 300, 0.01, 1 ));
				_audioGroup.addAudioToEntity( entity );
				entity.add( new Sleep(true, false) );
				
				BitmapTimelineCreator.convertToBitmapTimeline(entity, EntityUtils.getDisplayObject(entity) as MovieClip, true, fallBitmapSequence, _bitmapQuality);
//				if( number != 2 )
//				{
//					Spatial(entity.get(Spatial)).scaleY *= -1;	// NOTE :: this accounts for something in the bitmap process flipping the y scale, even though only the x scale was flipped. - bard
//				}
				// just made a new library clip of the waterfalls facing the other way and they should now be all set
				
				// falls foam				
				var emitter:Emitter2D = new Emitter2D();
				var start:Boolean = false;
				var counterNum:int = 35;
				var particleSize:int = 10;
				if( PlatformUtils.isDesktop )
				{
					emitter.counter = new Steady(counterNum);
					emitter.addInitializer( new ImageClass( Blob, [particleSize, 0xEEEEEE], true ) );
				}
				else
				{
					if( PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_MEDIUM )
					{
						counterNum = 15;
						particleSize = 8;
					}
					emitter.counter = new Steady(counterNum);
					var bitmapData:BitmapData = BitmapUtils.createBitmapData( new Blob(particleSize, 0xEEEEEE) );
					emitter.addInitializer(  new BitmapImage(bitmapData, true) );
				}
				emitter.addInitializer( new AlphaInit( .6, .7 ));
				emitter.addInitializer( new Lifetime( 1, 1.5 )); 
				emitter.addInitializer( new Velocity( new LineZone( new Point( -25, -25 ), new Point( 25, -20 ))));
				emitter.addInitializer( new Position( new EllipseZone( new Point( 0, 0 ), 80, 10 )));
				emitter.addInitializer( new Rotation(0,360));
				
				emitter.addAction( new Move());
				emitter.addAction( new Age( org.flintparticles.common.easing.Quadratic.easeOut ));
				emitter.addAction( new ScaleImage( 1.5, 2.5 ));
				emitter.addAction( new Fade( .7, 0 ));
				emitter.addAction( new Accelerate( 0, 25 ));
				
				
				switch( number )
				{
					case 0:
						lever.pathIn = getEntityById( "way0" ).get( WaterWayComponent );
						lever.pathOut = getEntityById( "way2" ).get( WaterWayComponent );
						lever.altPathOut = getEntityById( "fall0" ).get( WaterWayComponent );
						waterWay.feedsInto = getEntityById( "way1" ).get( WaterWayComponent );
						waterWay.foamOn = true;
						start = true;
						break;
					case 1:
						lever.pathIn = getEntityById( "way2" ).get( WaterWayComponent );
						lever.pathOut = getEntityById( "fall1" ).get( WaterWayComponent );
						lever.altPathOut = getEntityById( "way3" ).get( WaterWayComponent );
						waterWay.feedsInto = getEntityById( "way4" ).get( WaterWayComponent );
						break;
					case 2:
						lever.pathIn = getEntityById( "way5" ).get( WaterWayComponent );
						lever.pathOut = getEntityById( "fall2" ).get( WaterWayComponent );
						lever.altPathOut = getEntityById( "way6" ).get( WaterWayComponent );
						waterWay.feedsInto = getEntityById( "way7" ).get( WaterWayComponent );
						break;
					case 3:
						lever.pathIn = getEntityById( "way8" ).get( WaterWayComponent );
						lever.pathOut = getEntityById( "fall3" ).get( WaterWayComponent );
						lever.altPathOut = getEntityById( "way9" ).get( WaterWayComponent );
						break;
				}
				
				var emitterEntity:Entity = EmitterCreator.create( this, _hitContainer[ "foam" + number ], emitter, 0, -10, null, "foam" + number, null, start );
				
				waterWay.emitterCounter = emitter.counter;
				waterWay.emitter = emitterEntity.get( Emitter );
			}
			
			addSystem( new AquaductSystem(), SystemPriorities.update );
			addSystem( new BridgeSystem(), SystemPriorities.update );
			addSystem( new WaterWaySystem(), SystemPriorities.update );
		}
		
		private function setupZees():void
		{
			var display:Display;
			var clip:MovieClip;
			var entity:Entity;
			var number:int;
			
			for( number = 1; number < 11; number ++ )
			{
				clip = _hitContainer[ "z" + number ];
				
				if( shellApi.checkEvent( _events.SPHINX_FLOODED ))
				{
					clip.visible = false;	
				}
					
				else
				{
					entity = EntityUtils.createSpatialEntity( this, clip );
					entity.add( new Id( "z" + number ));
					
					display = entity.get( Display );
					display.alpha = 0;
					
					SceneUtil.addTimedEvent( this, new TimedEvent(( 1 + ( number / 5 )), 1, Command.create( resetZs, entity )));
					entity.add( new Tween());
					if(!PlatformUtils.isDesktop)
					{
						DisplayUtils.bitmapDisplayComponent(entity,true,1);
					}
				}
			}
		}
		
		private function resetZs( entity:Entity ):void
		{
			var display:Display = entity.get( Display );
			var spatial:Spatial = entity.get( Spatial );
			var tween:Tween = entity.get( Tween );
			
			spatial.x = 1280;
			spatial.y = 2175;
			display.alpha = 1;
			
			var _x:Number = spatial.x - ( Math.random() * 10 ) - 10;
			var _y:Number = spatial.y - 200;
			
			var func:Function = resetZs;
			var params:Array = [ entity ];
			
			if( !_awake )
			{
				tween.to( display, 3, { alpha : 0 });
				tween.to( spatial, 3, { x : _x, y : _y, onComplete : func, onCompleteParams : params}); 
			}	
		}
		
		private function pushBridge( char:Entity, entity:Entity ):void
		{
			SceneUtil.lockInput( this );
			
			var bridge:BridgeComponent = entity.get( BridgeComponent );
			var creator:HitCreator = new HitCreator();
			var platform:Entity = bridge.pathEntity;
			
			creator.makeHit( platform, HitType.PLATFORM );
			
			var id:String = Id( entity.get( Id )).id.slice( 12 ); 
			if( id == "1" )
			{
				CharUtils.setDirection( player, true );
			}
			else
			{
				CharUtils.setDirection( player, false );
			}
			
			CharUtils.setAnim( player, Push, false, 20 );
			SceneUtil.addTimedEvent( this, new TimedEvent( .5, 1, Command.create( dropBridge, entity )));
		}
		
		private function dropBridge( entity:Entity ):void
		{
			var audio:Audio = entity.get( Audio );
			audio.playCurrentAction( TRIGGER );
			
			var bridge:BridgeComponent = entity.get( BridgeComponent );
			var sceneInteraction:SceneInteraction = entity.get( SceneInteraction );
			sceneInteraction.minTargetDelta.x = 20;
			sceneInteraction.motionToZero = new <String>["x"];
			var spatial:Spatial = bridge.displayEntity.get( Spatial );
			var tween:Tween = entity.get( Tween );
			
			sceneInteraction.reached.removeAll();
			entity.remove( Interaction );
			entity.remove( SceneInteraction );
			entity.remove( ToolTip );
			
			tween.to( spatial, .8, { rotation : bridge.fallRotation, ease : fl.motion.easing.Quadratic.easeIn, onComplete : rebound, onCompleteParams : [ entity ]});
		}
		
		private function rebound( entity:Entity ):void
		{
			//	spatial.rotation = bridge.fallRotation;
			var bridge:BridgeComponent = entity.get( BridgeComponent );
			var spatial:Spatial = bridge.displayEntity.get( Spatial );
			var tween:Tween = entity.get( Tween );
			
			tween.to( spatial, .5, { rotation : bridge.reboundOne, ease : fl.motion.easing.Quadratic.easeOut, onComplete : secondFall, onCompleteParams : [ entity ]});
		}
		
		private function secondFall( entity:Entity ):void
		{
			var bridge:BridgeComponent = entity.get( BridgeComponent );
			var spatial:Spatial = bridge.displayEntity.get( Spatial );
			var tween:Tween = entity.get( Tween );
			
			tween.to( spatial, .5, { rotation : bridge.fallRotation, ease : fl.motion.easing.Quadratic.easeIn, onComplete : secondRebound, onCompleteParams : [ entity ]});
		}
		
		private function secondRebound( entity:Entity ):void
		{
			//	spatial.rotation = bridge.fallRotation;
			var bridge:BridgeComponent = entity.get( BridgeComponent );
			var spatial:Spatial = bridge.displayEntity.get( Spatial );
			var tween:Tween = entity.get( Tween );
			
			tween.to( spatial, .3, { rotation : bridge.reboundTwo, ease : fl.motion.easing.Quadratic.easeOut, onComplete : thirdFall, onCompleteParams : [ entity ]});
		}
		
		private function thirdFall( entity:Entity ):void
		{
			var bridge:BridgeComponent = entity.get( BridgeComponent );
			var spatial:Spatial = bridge.displayEntity.get( Spatial );
			var tween:Tween = entity.get( Tween );
			
			tween.to( spatial, .3, { rotation : bridge.fallRotation, ease : fl.motion.easing.Quadratic.easeIn, onComplete : addBridgePath, onCompleteParams : [ entity ]});
		}
		
		private function addBridgePath( entity:Entity ):void
		{
			var bridge:BridgeComponent = entity.get( BridgeComponent );
			bridge.isDown = true;
			SceneUtil.lockInput( this, false );
		}
		
		private function moveLever( char:Entity, entity:Entity ):void
		{			
			SceneUtil.lockInput( this );

			var audio:Audio = entity.get( Audio );
			audio.playCurrentAction( TRIGGER );
			
			var lever:LeverComponent = entity.get( LeverComponent );
			//			var id:String = Id( entity.get( Id )).id.slice( 5 ); 
			var spatial:Spatial = entity.get( Spatial );
			var playerSpatial:Spatial = player.get( Spatial );
			var waterWay:WaterWayComponent;
			var degree:Number;
			var tween:Tween = new Tween();
			var params:Array = new Array( entity );
			
			playerSpatial.x = spatial.x;
			
			var goal:Number;
			
			if( lever.isLeft )
			{
				goal = playerSpatial.x + 80;
				CharUtils.setDirection( player, false );
				
				degree = MAX_THETA;
				lever.isLeft = false;
			}
			else
			{
				goal = playerSpatial.x - 80;
				CharUtils.setDirection( player, true );
				
				degree = MIN_THETA;
				lever.isLeft = true;
				params.push( false );
			}
			CharUtils.setAnim( player, Pull );
			
			tween.to( playerSpatial, 1, { x : goal });
			player.add( tween );
			
			tween = new Tween();
			tween.to( spatial, 1, { rotation : degree, onComplete : switchFlows, onCompleteParams : params });
			entity.add( tween );
			
			//			shellApi.triggerEvent( "turn_lever_" + id );
		}
		
		private function setStand():void
		{
			SceneUtil.lockInput( this, false );
		}
		
		private function switchFlows( leverEntity:Entity, isLeft:Boolean = true ):void
		{
			SceneUtil.lockInput( this, false );
			CharUtils.setState( player, CharacterState.STAND );
			
			var lever:LeverComponent = leverEntity.get( LeverComponent );
			var waterWay:WaterWayComponent;
			
			if( lever.leftIsAlt )
			{
				if( isLeft )
				{
					waterWay = lever.altPathOut;
				}
					
				else
				{
					waterWay = lever.pathOut;
				}
				
				waterWay.isOn = false;
				
				if( waterWay.isFall )
				{
					waterWay.feedsInto.isOn = false;
				}
			}
			else
			{
				if( isLeft )
				{
					waterWay = lever.pathOut;
				}
					
				else
				{
					waterWay = lever.altPathOut;
				}
				
				waterWay.isOn = false;
				
				if( waterWay.isFall )
				{
					if( waterWay.feedsInto )
					{
						waterWay.feedsInto..isOn = false;
					}
				}
			}
		}
		
		/*******************************
		 * 		     ON FLOODED
		 * *****************************/
		private function floodBackground():void
		{
			var audio:Audio;
			var entity:Entity;

			super.shellApi.triggerEvent( _events.SPHINX_FLOODED, true );
			
			// active waterfall ripples
			entity = getEntityById( "ripples" );
			var ripplesDisplay:DisplayObjectContainer = EntityUtils.getDisplayObject(entity);
			audio = entity.get( Audio );
			audio.playCurrentAction( TRIGGER );
			Sleep( entity.get( Sleep ) ).ignoreOffscreenSleep = false;

			var numFalls:int = 6;
			var ripplesClip:MovieClip;
			for (var i:int = 0; i < numFalls; i++) 
			{
				// if performance is high, play ripple animations, otherwise merely make visible
				if( PerformanceUtils.qualityLevel > PerformanceUtils.QUALITY_LOW )
				{
					entity = getEntityById( "ripple_" + i );
					Display( entity.get( Display )).visible = true;
					Timeline(entity.get(Timeline)).playing = true;
					Sleep(entity.get(Sleep)).ignoreOffscreenSleep = false;
				}
				else
				{
					if( ripplesClip == null ) 	{ ripplesClip = _hitContainer[ "ripples" ] as MovieClip; }
					ripplesClip.getChildAt(i).visible = true;
				}
			}

			// activate layers
			var floodedBG:Entity = getEntityById( "floodedBackground" );
			var sleep:Sleep = floodedBG.get( Sleep );
			sleep.sleeping = false;
			Display( floodedBG.get( Display )).visible = true;
			
			var floodedFG:Entity = getEntityById( "floodedForeground" );
			Sleep( floodedFG.get( Sleep )).sleeping = false;
			Display( floodedFG.get( Display )).visible = true;
			
			// activate flower
			EntityUtils.visible( getEntityById( "flower" ), true );
			var spatial:Spatial = getEntityById( "flowerSparkle" ).get( Spatial );
			spatial.x += 30;
			spatial.y -= 50;

			// update sphinx
			if( !super.shellApi.checkEvent( _events.SPHINX_AWAKE ))
			{
				entity = getEntityById( "sphinx" );
				audio = entity.get( Audio );
				audio.playCurrentAction( TRIGGER );
				super.shellApi.triggerEvent( _events.SPHINX_AWAKE, true );
			}
			
			Sleep(getEntityById( "waterHit" ).get( Sleep )).sleeping = false;
		}
		
		private function getFlower( char:Entity, flowerTarget:Entity ):void
		{
			if( shellApi.checkEvent( _events.SPHINX_FLOODED ))
			{
				SceneUtil.lockInput( this );
				super.shellApi.getItem( SPHINX_FLOWER, null, true );
				var showItem:ShowItem = getGroupById( "showItemGroup" ) as ShowItem;
				showItem.transitionComplete.addOnce( sphinxPraise );
				
				super.removeEntity( flowerTarget );
				super.removeEntity( getEntityById( "flowerSparkle" ) );
				super.removeEntity( getEntityById( "flower" ) );
				
				var mouthEntity:Entity = getEntityById( "mouth" );
				var timeline:Timeline = mouthEntity.get( Timeline );
				timeline.gotoAndStop( "awake" );
			}
			else
			{
				var sphinxEntity:Entity = getEntityById( "sphinx" );
				
				wakeSphinx( true );
				
				SceneUtil.lockInput( this );
				SceneUtil.setCameraTarget( this, sphinxEntity );
				CharUtils.setDirection( player, false );
				
				if( !shellApi.checkEvent( _events.SPHINX_AWAKE ))
				{
					var audio:Audio = sphinxEntity.get( Audio );
					audio.playCurrentAction( TRIGGER );
				}
				
				var dialog:Dialog = sphinxEntity.get( Dialog );
				dialog.sayById( "wake_sphinx" );
				dialog.complete.addOnce( whatDoIDo );
			}
		}
		
		/*******************************
		 * 		  SPHINX RIDDLE
		 * *****************************/
		private function whatDoIDo( dialogData:DialogData ):void
		{
			SceneUtil.setCameraTarget( this, player );
			
			var entity:Entity = super.getEntityById( "mouth" );
			var timeline:Timeline = entity.get( Timeline );
			timeline.gotoAndStop( "awake" );
			
			var dialog:Dialog = player.get( Dialog );
			dialog.sayById( "what" );
			dialog.complete.addOnce( poseRiddle );
		}
		
		private function poseRiddle( dialogData:DialogData ):void
		{
			var entity:Entity = super.getEntityById( "sphinx" );	
			var dialog:Dialog = entity.get( Dialog );
			
			SceneUtil.setCameraTarget( this, entity );
			
			entity = super.getEntityById( "mouth" );
			var timeline:Timeline = entity.get( Timeline );
			timeline.gotoAndPlay( "talk" );
			
			dialog.sayById( "once_wet" );
			dialog.complete.addOnce( middleRiddle );
		}
		
		private function middleRiddle( dialogData:DialogData ):void
		{
			var entity:Entity = super.getEntityById( "sphinx" );
			var dialog:Dialog = entity.get( Dialog );
			
			dialog.sayById( "flows" );
			dialog.complete.addOnce( endRiddle );
		}
		
		private function endRiddle( dialogData:DialogData ):void
		{
			var entity:Entity = super.getEntityById( "sphinx" );
			var dialog:Dialog = entity.get( Dialog );
			
			dialog.sayById( "rose" );
			dialog.complete.addOnce( finishedRiddle );
		}
		
		private function finishedRiddle( dialogData:DialogData ):void
		{
			SceneUtil.setCameraTarget( this, player );
			SceneUtil.lockInput( this, false );
			
			if( !super.shellApi.checkEvent( _events.SPHINX_AWAKE ))
			{
				super.shellApi.triggerEvent( _events.SPHINX_AWAKE, true );
			}
			
			var entity:Entity = super.getEntityById( "mouth" );
			var timeline:Timeline = entity.get( Timeline );
			timeline.gotoAndStop( "awake" );
		}
		
		private function sphinxPraise():void
		{
			var entity:Entity = super.getEntityById( "sphinx" );
			var dialog:Dialog = entity.get( Dialog );
			
			SceneUtil.setCameraTarget( this, entity );
			CharUtils.setDirection( player, false );
			
			entity = super.getEntityById( "mouth" );
			var timeline:Timeline = entity.get( Timeline );
			timeline.gotoAndPlay( "talk" );
			
			dialog.sayById( "praise" );
			dialog.complete.addOnce( haveFlower );
		}
		
		private function haveFlower( dialogData:DialogData ):void
		{
			SceneUtil.lockInput( this, false );
			SceneUtil.setCameraTarget( this, player );
			
			var entity:Entity = super.getEntityById( "mouth" );
			var timeline:Timeline = entity.get( Timeline );
			timeline.gotoAndStop( "awake" );
		}
		
		private const SPHINX_FLOWER:String = "sphinxFlower";
		private const TRIGGER:String = "trigger";
		
		private var _nearLabyrinth:Boolean = false;
		private var _flooded:Boolean = false;
		private var _awake:Boolean = false;
		private var _openAthena:Boolean;
		private var _bitmapQuality:Number = 1;

		private var MIN_THETA:Number = -60;
		private var MAX_THETA:Number = 60;
	}
}