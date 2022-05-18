package game.scenes.survival2.beaverDen
{
	import com.greensock.easing.Linear;
	
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Camera;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.components.SpatialAddition;
	import engine.components.Tween;
	import engine.util.Command;
	
	import game.components.entity.Dialog;
	import game.components.entity.Sleep;
	import game.components.entity.collider.BitmapCollider;
	import game.components.entity.collider.SceneCollider;
	import game.components.entity.collider.WaterCollider;
	import game.components.hit.Item;
	import game.components.hit.Platform;
	import game.components.hit.Water;
	import game.components.hit.Zone;
	import game.components.motion.Edge;
	import game.components.motion.FollowTarget;
	import game.components.motion.MotionControl;
	import game.components.motion.SceneObjectMotion;
	import game.components.motion.ShakeMotion;
	import game.components.motion.TargetSpatial;
	import game.components.motion.WaveMotion;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.Timeline;
	import game.creators.entity.BitmapTimelineCreator;
	import game.creators.entity.EmitterCreator;
	import game.creators.scene.SceneItemCreator;
	import game.data.TimedEvent;
	import game.data.WaveMotionData;
	import game.data.scene.characterDialog.DialogData;
	import game.scene.template.AudioGroup;
	import game.scene.template.CameraGroup;
	import game.scenes.carnival.shared.ferrisWheel.components.StickyPlatform;
	import game.scenes.carnival.shared.ferrisWheel.systems.StickyPlatformSystem;
	import game.scenes.survival1.shared.components.TriggerHit;
	import game.scenes.survival1.shared.systems.TriggerHitSystem;
	import game.scenes.survival2.Survival2Events;
	import game.scenes.survival2.beaverDen.components.BeaverComponent;
	import game.scenes.survival2.beaverDen.components.DamControlComponent;
	import game.scenes.survival2.beaverDen.components.DamTriggerPlatformComponent;
	import game.scenes.survival2.beaverDen.components.LeakComponent;
	import game.scenes.survival2.beaverDen.components.TreeLogComponent;
	import game.scenes.survival2.beaverDen.systems.BeaverSystem;
	import game.scenes.survival2.beaverDen.systems.DamControlSystem;
	import game.scenes.survival2.beaverDen.systems.DamLeakSystem;
	import game.scenes.survival2.shared.Survival2Scene;
	import game.scenes.survival2.shared.flippingRocks.FlipGroup;
	import game.systems.hit.ItemHitSystem;
	import game.systems.hit.WaterHitSystem;
	import game.systems.motion.SceneObjectMotionSystem;
	import game.systems.motion.WaveMotionSystem;
	import game.systems.timeline.BitmapSequenceSystem;
	import game.util.BitmapUtils;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.PerformanceUtils;
	import game.util.PlatformUtils;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	import game.util.TweenUtils;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.Fade;
	import org.flintparticles.common.actions.ScaleImage;
	import org.flintparticles.common.counters.ZeroCounter;
	import org.flintparticles.common.displayObjects.Blob;
	import org.flintparticles.common.displayObjects.Ring;
	import org.flintparticles.common.easing.Quadratic;
	import org.flintparticles.common.initializers.AlphaInit;
	import org.flintparticles.common.initializers.BitmapImage;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.DeathZone;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.RandomDrift;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.EllipseZone;
	import org.flintparticles.twoD.zones.RectangleZone;
	
	public class BeaverDen extends Survival2Scene
	{
		private const HIT:String 			= "hit";
		
		private const LOG_DENSITY:Number 		= .25;
		private const PLAYER_WEIGHT:Number 		= .45;
		private const BUOYANCY_DAMPENER:Number 	= .12;
		private const MAX_Y_VEL:Number 			= 250;
		private const WATER_WIDTH:Number = 2350;
		public static const DAM_DRAINED_Y:int = 2000;
		
		
		private var _audioGroup:AudioGroup;
		//private var _damControl:DamControlComponent = new DamControlComponent();
		private var _dam:Entity;
		private var _defaultCameraZoom:Number;
		private var _cameraEntity:Entity;
		private var _customTarget:Spatial;
		private var _events:Survival2Events;
		private var _zoomSpatial:Spatial;
		private var _waterEntity:Entity;
		private var _firstHit:Boolean = true;
		
		public function BeaverDen()
		{
			//showHits = true;
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/survival2/beaverDen/";
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
			
			_events = super.events as Survival2Events;
			
			_cameraEntity = super.getEntityById("camera");
			var camera:Camera = _cameraEntity.get( Camera );
			var cameraGroup:CameraGroup = getGroupById( CameraGroup.GROUP_ID, this ) as CameraGroup;
			
			var zoomEntity:Entity = EntityUtils.createSpatialEntity( this, _hitContainer[ "zoomTarget" ]);
			_zoomSpatial = zoomEntity.get( Spatial );
			_defaultCameraZoom = cameraGroup.zoomTarget;
			_audioGroup = getGroupById( AudioGroup.GROUP_ID ) as AudioGroup;
			
			setupWaterfall();
			setupScene();
			
			// setup dam puzzle
			setupWater();
			setupBeavers();
			setupHook();
			setupIce();
			setupHoles();
			setupLogs();
			setupDam();

			// add systems
			addSystem(new BitmapSequenceSystem());
			addSystem( new TriggerHitSystem());
			addSystem(new WaveMotionSystem());
			addSystem( new StickyPlatformSystem());
			addSystem(new SceneObjectMotionSystem());
			
			// add beaver puzzle systems
			if( !shellApi.checkEvent( _events.DAM_DRAINED ) )
			{
				WaterHitSystem(getSystem(WaterHitSystem)).playerWeight = PLAYER_WEIGHT;
				
				var damControlSystem:DamControlSystem = new DamControlSystem();
				damControlSystem.hit.add( hitDam );
				addSystem( damControlSystem);	// node must be created before BeaverSystem or DamLeakSystem or created
				
				addSystem( new DamLeakSystem() );
				
				var beaverSystem:BeaverSystem = new BeaverSystem();
				beaverSystem.victory.add( endPuzzle );
				addSystem( beaverSystem );
				
				ready.addOnce(repositionLogs);
			}
			
			super.loaded();
		}
		
		private function repositionLogs(...args):void
		{
			for(var i:int = 1; i <= 3; i++)
			{
				var log:Entity = getEntityById("floatingLogHit"+i);
				Spatial(log.get(Spatial)).y = 1000;
			}
		}
		
		public function setupWaterfall():void
		{
			var clip:MovieClip = _hitContainer["riverfall"];
			DisplayUtils.moveToTop(clip);
			var entity:Entity = BitmapTimelineCreator.createBitmapTimeline(clip);
			this.addEntity(entity);
			Timeline(entity.get(Timeline)).play();
			_audioGroup.addAudioToEntity( entity );
			entity.add( new AudioRange( 600, 0.03, 2 )); 
			var audio:Audio = entity.get( Audio );
			audio.playCurrentAction( "loop" );
		}

		public function setupScene():void
		{			
			var bounceEntity:Entity
			var clip:MovieClip;
			var display:Display;
			var entity:Entity;
			var flipGroup:FlipGroup;
			var interaction:Interaction;
			var itemHitSystem:ItemHitSystem;
			var number:int;
			var platformEntity:Entity;
			var rock:Entity;
			var timeline:Timeline;
			
			// FLIP STONE
			flipGroup = new FlipGroup( this, _hitContainer );
			addChildGroup( flipGroup );
			
			rock = flipGroup.createFlippingEntity( _hitContainer[ "stone" ], "flipstone", 5, 2, false, 2 );
			
			// GRUBS ITEM
			clip = _hitContainer[ "grubs" ];
			
			if( !shellApi.checkHasItem( _events.GRUBS ))
			{
				if(PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_HIGHEST) BitmapUtils.convertContainer(clip);
				var sceneCreator:SceneItemCreator = new SceneItemCreator();
				entity = EntityUtils.createSpatialEntity( this, clip );
				TimelineUtils.convertClip( clip, this, entity );
				entity.add( new Id( "grubs" ));
				sceneCreator.make( entity, new Point( 25, 100 ));
				//BitmapTimelineCreator.convertToBitmapTimeline( entity, clip );
				//Timeline(entity.get(Timeline)).play();
				
				itemHitSystem = getSystem( ItemHitSystem ) as ItemHitSystem;
				if( !itemHitSystem )
				{
					itemHitSystem = new ItemHitSystem();
					addSystem( itemHitSystem );
				}
				
				timeline = rock.get( Timeline );
				timeline.labelReached.add( rockFlip );
			}
			else
			{
				_hitContainer.removeChild(clip);
			}
			
			for( number = 1; number < 6; number++ )
			{
				// SPRING BRANCHES
				clip = _hitContainer[ "branch" + number ];
				if(PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_HIGHEST)  BitmapUtils.convertContainer(clip);
				bounceEntity = getEntityById( "bounce" + number );
				entity = EntityUtils.createSpatialEntity( this, clip );
				entity.add( new Id( "branch" + number ));
				//BitmapTimelineCreator.convertToBitmapTimeline( entity, clip );
				TimelineUtils.convertClip(clip, this, entity, null,false);
				bounceEntity.add( new TriggerHit( entity.get( Timeline )));
				// WEEDS
				clip = _hitContainer[ "weed" + number ];
				if(shellApi.checkEvent(_events.DAM_DRAINED) || PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_HIGHEST)
				{
					_hitContainer.removeChild(clip);
					continue;
				}
				if(PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_HIGHEST) BitmapUtils.convertContainer(clip);
				entity = EntityUtils.createSpatialEntity( this, clip );
				entity.add( new Id( "weed" + number ));
				TimelineUtils.convertClip(clip, this, entity);
			}
			
			// CHIPMUNK
			convertCritter( "chipmunk" );
			
			// FOX
			convertCritter( "fox" );
		}
		
		private function convertCritter( critter:String ):void
		{
			var clip:MovieClip;
			var entity:Entity;
			var interactionEntity:Entity;
			var interaction:Interaction;
			var timeline:Timeline;
			
			clip = _hitContainer[ critter ];
			
			interactionEntity = getEntityById( critter + "Interaction" );
			
			if(PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_HIGHEST / 2)
			{
				removeEntity(interactionEntity);
				_hitContainer.removeChild(clip);
				return;
			}
			
			this.convertContainer(clip);
			
			entity = EntityUtils.createSpatialEntity( this, clip );
			entity.add( new Id( critter ))
			TimelineUtils.convertClip(clip, this, entity);
			
			timeline = entity.get( Timeline );
			timeline.handleLabel( "trigger", Command.create( triggerSound, entity ), false );
			timeline.gotoAndStop( "start" );
			
			SceneInteraction(interactionEntity.get(SceneInteraction)).triggered.removeAll();
			interactionEntity.remove(SceneInteraction);
			interaction = interactionEntity.get( Interaction );
			interaction.click.add( Command.create( playTimeline, entity ));
			_audioGroup.addAudioToEntity( entity );
		}
		
		private function playTimeline( interactionEntity:Entity, critterEntity:Entity ):void
		{
			var timeline:Timeline = critterEntity.get( Timeline );
			timeline.play();
		}
		
		private function triggerSound( interactionEntity:Entity ):void
		{
			var audio:Audio = interactionEntity.get( Audio );
			audio.playCurrentAction( "hit" );
		}
		
		private function rockFlip( label:String ):void
		{
			var grubs:Entity = getEntityById( "grubs" );
			if(grubs != null)
			{
				var sceneCreator:SceneItemCreator = new SceneItemCreator();
				
				if( label == "position2" )
				{
					grubs.remove( SceneInteraction );
					grubs.remove( Item );
				}
				else
				{
					if(grubs.get(Item) == null)
						sceneCreator.make( grubs, new Point( 25, 100 ));
				}
			}
		}
		
		private function setupWater():void
		{
			_waterEntity = super.getEntityById( "waterHit" );
			if( !shellApi.checkEvent( _events.DAM_DRAINED ) )
			{
				var waterHit:Water = _waterEntity.get(Water);
				EntityUtils.visible( _waterEntity, true );
				_waterEntity.add( new Sleep( false, true ));
				var disp:Display = _waterEntity.get(Display);
				disp.isStatic = false;
				disp.moveToFront();
				BitmapUtils.convertContainer(disp.displayObject);
				Spatial(_waterEntity.get(Spatial)).scaleX = WATER_WIDTH;
			}
			else
			{
				super.removeEntity( _waterEntity ); 
				_waterEntity = null;
			}
		}
		
		private function setupBeavers():void
		{
			var numBeavers:uint = 2;
			var i:uint = 1;
			if( shellApi.checkEvent( _events.DAM_DRAINED ) ) 
			{
				for( i = 1; i <= numBeavers; i++ )
				{
					_hitContainer.removeChild( _hitContainer[ "beaver" + i ] );
				}
			}
			else
			{
				var clip:MovieClip;
				var beaver:BeaverComponent;
				var beaverEntity:Entity;
				var sleep:Sleep;
				var spatial:Spatial;
				var timeline:Timeline;
				
				for( i = 1; i <= numBeavers; i++ )
				{
					clip = _hitContainer[ "beaver" + i ];
					if(PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_HIGHEST) BitmapUtils.convertContainer(clip);
					beaverEntity = EntityUtils.createMovingEntity( this, clip );
					spatial = beaverEntity.get( Spatial );
					beaver = new BeaverComponent();
					beaverEntity.add( new Id( "beaver" + i )).add( beaver ).add( new Tween());
					if( i == 1 )
					{
						beaver.subState = beaver.FRO;
					}
					
					TimelineUtils.convertClip( clip, this, beaverEntity );
					timeline = beaverEntity.get( Timeline );
					timeline.gotoAndPlay( "startswim" );
					
					sleep = beaverEntity.get( Sleep );
					sleep.ignoreOffscreenSleep = true;
					sleep.sleeping = false;
					
					_audioGroup.addAudioToEntity( beaverEntity );
					beaverEntity.add( new AudioRange( 600, .01, 2 ));
				}
			}
		}

		private function setupHook():void
		{
			var hook:Entity = getEntityById( "hook" );
			var hookZone:Entity = getEntityById( "hookZone" );
			if( hook )
			{
				SceneInteraction( hook.get( SceneInteraction ) ).ignorePlatformTarget = false;
				Interaction( hook.get( Interaction ) ).click.add( noticeHook );
				
				Zone( hookZone.get( Zone ) ).entered.addOnce( noticeHook );
			}
			else
			{
				removeEntity(hookZone);
			}
		}
		
		private function setupIce():void
		{
			var i:uint;
			var clip:Sprite;

			var entity:Entity
			for( i = 1; i < 6; i ++ )
			{
				clip = _hitContainer["ice" + i ] as Sprite;
				if(PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_HIGHEST || shellApi.checkEvent( _events.DAM_DRAINED ))
				{
					_hitContainer.removeChild(clip);
				}
				else
				{
					if( !PlatformUtils.inBrowser || true )	
					{ 
						clip = super.convertToBitmapSprite(clip, null, true, PerformanceUtils.defaultBitmapQuality).sprite;
					}
					
					entity = EntityUtils.createSpatialEntity( this, clip);
					entity.add( new Id( "ice" + i ));
				
					var waveMotionData:WaveMotionData = new WaveMotionData();
					waveMotionData.property = "rotation";
					waveMotionData.magnitude = 2;
					waveMotionData.rate = .05;
					waveMotionData.radians = 0;
					
					var waveMotion:WaveMotion = new WaveMotion();
					waveMotion.data.push( waveMotionData );
					entity.add( waveMotion );
					
					entity.add( new SpatialAddition() );
					entity.add( new Motion());
					entity.add( new Edge( -15, -15, 30, 50 ) );

					var waterCollider:WaterCollider = new WaterCollider();
					waterCollider.density = .9;
					entity.add( waterCollider );
					entity.add( new SceneObjectMotion());	// applies gravity
					
					EntityUtils.addParentChild( entity, _waterEntity );
				}
			}
		}
		
		private function setupHoles():void
		{
			var clip:MovieClip;
			var i:uint = 1;
			if( shellApi.checkEvent( _events.DAM_DRAINED ) )
			{
				for( i; i < 4; i++ )
				{
					clip = _hitContainer[ "hole" + i ];
					_hitContainer.removeChild( clip );
				}
			}
			else
			{
				var container:DisplayObjectContainer;
				var emitter:Emitter2D;
				var holeEntity:Entity;
				var leak:LeakComponent;
				
				var bubble:BitmapData = BitmapUtils.createBitmapData(new Ring( 5, 7, 0xFFFFF ));
				var blob:BitmapData = BitmapUtils.createBitmapData(new Blob( 7, 0x6D5E38 ));
				var waterTop:int = Spatial(_waterEntity.get(Spatial)).y;
				var emitterRateUnit:int = Math.floor(PerformanceUtils.qualityLevel / 30);
				for( i; i < 4; i++ )
				{
					// HOLES
					clip = _hitContainer[ "hole" + i ];
					if(PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_HIGHEST)  BitmapUtils.convertContainer(clip);

					holeEntity = EntityUtils.createSpatialEntity( this, clip );
					MovieClip(EntityUtils.getDisplayObject( holeEntity )).gotoAndStop(1);
					holeEntity.add( new Id( "hole" + i ));
		
					_audioGroup.addAudioToEntity( holeEntity );
					holeEntity.add( new AudioRange( 600, .01, 2 ))
					holeEntity.add( new Sleep( false, true ) );

					// add bubble emitter to the holes
					
					container = _hitContainer[ "bubbles" + i ];
					emitter = new Emitter2D();
					emitter.counter = new ZeroCounter();
					
					emitter.addInitializer( new BitmapImage(bubble, true));
					emitter.addInitializer( new AlphaInit( .5, .75 ));
					emitter.addInitializer( new Lifetime( 1, 2 )); 
					emitter.addInitializer( new Velocity( new RectangleZone( -150, -20, 150, 35 ) ));
					emitter.addInitializer( new Position( new EllipseZone( new Point( 0,0 ), 4, 3 )));
					
					emitter.addAction( new Age( Quadratic.easeOut ));
					emitter.addAction( new Move());
					emitter.addAction( new RandomDrift( 130, 15 ));
					emitter.addAction( new ScaleImage( .7, 1.5 ));
					emitter.addAction( new Fade( .75, 0 ));
					emitter.addAction( new Accelerate( 0, -15 ));
					var deathZone:DeathZone = new DeathZone( new RectangleZone( -40, waterTop - 1220, 40, 40 ), true );
					emitter.addAction( deathZone );
					EmitterCreator.create( this, container, emitter, 0, 0, holeEntity, "holeEmitter" + i );
					
					leak = new LeakComponent();
					leak.spawnY = holeEntity.get( Spatial ).y;
					leak.bubbleEmitter = emitter;
					leak.deathZone = deathZone;
					leak.emitterRateUnit = emitterRateUnit;
					
					holeEntity.add( leak );
				}
			}
		}
		
		private function setupLogs():void
		{
			var i:uint = 1;
			if( shellApi.checkEvent( _events.DAM_DRAINED ) )
			{
				for( i; i < 4; i ++ )
				{
					_hitContainer.removeChild(  _hitContainer[ "underHit" + i ] );
					removeEntity( getEntityById( "floatingLogHit" + i ) )
					removeEntity( getEntityById( "floatingLog" + i ) );
				}
			}
			else
			{
				var entity:Entity;
				var hitEntity:Entity;
				var attackHitClip:DisplayObjectContainer;
				var edge:Edge;
				var followTarget:FollowTarget;
				var spatialAddition:SpatialAddition;
				var treeComponent:TreeLogComponent;
				var waterCollider:WaterCollider;
				var waveMotion:WaveMotion;
				var waveMotionData:WaveMotionData;
				
				//var maxYVel:Number = (super.player.get(CharacterMotionControl) as CharacterMotionControl).maxFallingVelocity;
				
				for( i; i < 4; i ++ )
				{
					entity = getEntityById( "floatingLog" + i );
					hitEntity = getEntityById( "floatingLogHit" + i );
					trace(hitEntity.getAll());
					attackHitClip = _hitContainer[ "underHit" + i ]
						
					if( PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_HIGHEST ) { BitmapUtils.createBitmapSprite(EntityUtils.getDisplayObject(entity)); }
					
					hitEntity.remove( SceneCollider );
					hitEntity.remove( BitmapCollider );
					Platform(hitEntity.get(Platform)).top = true;

					waterCollider = new WaterCollider();
					waterCollider.density = LOG_DENSITY;          
					waterCollider.dampener = BUOYANCY_DAMPENER;
					hitEntity.add( waterCollider );
					
					// if high performance add wave motion, otherwise exclude
					if( PerformanceUtils.qualityLevel >= PerformanceUtils.QUALITY_HIGHEST )
					{
						waveMotionData = new WaveMotionData();
						waveMotionData.property = "rotation";
						waveMotionData.magnitude = 2;
						waveMotionData.rate = .05;
						waveMotionData.radians = 0;
						
						waveMotion = new WaveMotion();
						waveMotion.data.push( waveMotionData );
						entity.add( waveMotion );
						
						spatialAddition = new SpatialAddition();
						entity.add( spatialAddition );
						hitEntity.add( spatialAddition );
					}

					var sleep:Sleep = hitEntity.get( Sleep );
					sleep.sleeping = false;
					sleep.ignoreOffscreenSleep = true;
	
					var motion:Motion = new Motion();
					//motion.friction = new Point( 0, 1000 );
					motion.maxVelocity = new Point( Infinity, this.MAX_Y_VEL );
					hitEntity.add( motion );
					
					edge = new Edge();
					var displayObject:DisplayObject = EntityUtils.getDisplayObject(hitEntity);
					edge.unscaled = displayObject.getBounds(displayObject);
					hitEntity.add( edge );
					
					var stickyPlatform:StickyPlatform = new StickyPlatform();
					hitEntity.add( stickyPlatform );

					followTarget = new FollowTarget( hitEntity.get( Spatial ));
					followTarget.offset = new Point( 0, edge.unscaled.bottom * Spatial(hitEntity.get(Spatial)).scaleY / 2 );
					EntityUtils.createSpatialEntity( this, attackHitClip ).add( followTarget );
					
					treeComponent = new TreeLogComponent();
					treeComponent.hit = attackHitClip;
					hitEntity.add( treeComponent );
					
					EntityUtils.addParentChild( entity, hitEntity );
					EntityUtils.addParentChild( hitEntity, _waterEntity );
				}
			}
		}
		
		private function setupDam():void
		{
			var damClip:DisplayObject = _hitContainer[ "damSide" ];
			DisplayUtils.moveToTop(damClip);
			damClip = this.createBitmapSprite(damClip);
			
			var battleZone:Entity = getEntityById( "battleZone" );
			if( shellApi.checkEvent( _events.DAM_DRAINED ) )
			{
				removeEntity( getEntityById( "beaverWalls" ) );
				removeEntity( battleZone );
			}
			else
			{
				// setup zone
				Zone(battleZone.get( Zone )).exitted.add( restoreZoom );
				
				// setup dam shake
				_dam = EntityUtils.createSpatialEntity( this, damClip );
				var shakeMotion:ShakeMotion = new ShakeMotion( new RectangleZone( -25, -1, 25, 1 ));
				shakeMotion.active = false;
				_dam.add( shakeMotion ).add( new SpatialAddition());
				
				//setup dam & dam platform
				var damEntity:Entity = getEntityById( "leakTrigger" );
				damEntity.add( new DamTriggerPlatformComponent());
				_audioGroup.addAudioToEntity( damEntity );
				
				var damControl:DamControlComponent = new DamControlComponent();
				damControl.waterSpatial = _waterEntity.get( Spatial );
				damEntity.add( damControl );
			}
		}

		/////////////////////////////////////////////////////////////////////////////////
		///////////////////////////////// HOOK SEQUENCES ////////////////////////////////
		/////////////////////////////////////////////////////////////////////////////////
		
		private function noticeHook( zoneId:String = null, colliderId:String = null ):void
		{
			var audio:Audio;
			var beaver:Entity;
			var hook:Entity = getEntityById( _events.HOOK );
			if(hook == null)
				return;
			var number:int;
			var targetSpatial:TargetSpatial = _cameraEntity.get( TargetSpatial );
			
			targetSpatial.target = hook.get( Spatial );
			
			SceneUtil.lockInput( this );
			//CharUtils.lockControls(player);
			
			SceneUtil.addTimedEvent( this, new TimedEvent( 1.5, 1, niceHook ));		
			
			for( number = 1; number < 3; number ++ )
			{
				beaver = getEntityById( "beaver" + number );
				if(beaver != null)
				{
					audio = beaver.get( Audio );
					audio.playCurrentAction( "alert" );
				}
			}
		}
		
		private function niceHook():void
		{
			var dialog:Dialog = player.get( Dialog );
			var targetSpatial:TargetSpatial = _cameraEntity.get( TargetSpatial );
			
			targetSpatial.target = player.get( Spatial );
			
			if( !shellApi.checkEvent( _events.DAM_DRAINED ))
			{
				dialog.sayById( "noticeHook" );
				dialog.complete.addOnce( renewedPurpose );
			}
			else
			{ 
				if(getEntityById(_events.HOOK) != null)
				{
					dialog.sayById( "nothingStoppingMe" );
					SceneUtil.lockInput( this, false );
				}
				else
				{
					renewedPurpose();
				}
			}
		}
		
		private function renewedPurpose( dialogData:DialogData = null ):void
		{
			//CharUtils.lockControls( player, false, false);
			SceneUtil.lockInput( this, false );
			MotionControl(player.get(MotionControl)).inputStateDown = false;
		}

		/////////////////////////////////////////////////////////////////////////////////
		///////////////////////////////// BEAVER BATTLE /////////////////////////////////
		/////////////////////////////////////////////////////////////////////////////////
		
		private function hitDam():void
		{
			var camera:Camera = _cameraEntity.get( Camera );
			var targetSpatial:TargetSpatial = _cameraEntity.get(TargetSpatial);
			
			var platformEntity:Entity = getEntityById( "leakTrigger" );
			var audio:Audio = platformEntity.get( Audio );
			audio.playCurrentAction( HIT );
			
			if( targetSpatial.target == player.get( Spatial ))
			{
				setCameraZoom( .75, .025, _zoomSpatial );
			}
			
			var shakeMotion:ShakeMotion = _dam.get( ShakeMotion );
			shakeMotion.active = true;
			
			SceneUtil.addTimedEvent( this, new TimedEvent( .25, 1, endShake ));
			
			if( _firstHit )
			{
				CharUtils.moveToTarget( player, 1840, 780, true, sayDialog );
				SceneUtil.lockInput( this );
			}
		}
		
		private function sayDialog( ...args ):void
		{
			CharUtils.setDirection( player, true );
			var dialog:Dialog = player.get( Dialog );
			dialog.sayById( "waterLeaking" );
			dialog.complete.addOnce( Command.create( startBeaver, 1 ) );
			dialog.complete.addOnce( stopThem );
		}
		
		private function stopThem( ...args):void
		{
			_firstHit = false;
			var dialog:Dialog = player.get( Dialog );
			dialog.sayById( "stopThem" );
			dialog.complete.addOnce( Command.create( startBeaver, 2 ) );
			CharUtils.lockControls( player, false, false );
			SceneUtil.lockInput( this, false );
		}
		
		private function startBeaver( dialog:DialogData, num:int ):void
		{
			var beaverEntity: Entity = getEntityById( "beaver" + num );
			Motion(beaverEntity.get(Motion)).zeroMotion();
			var beaverC:BeaverComponent = beaverEntity.get(BeaverComponent);
			beaverC.state = beaverC.IDLE;
		}
		
		private function endShake():void
		{
			var shakeMotion:ShakeMotion = _dam.get( ShakeMotion );
			var spatialAddition:SpatialAddition = _dam.get( SpatialAddition );
			
			shakeMotion.active = false;
			spatialAddition.x = spatialAddition.y =  0;
		}
		
		private function setCameraZoom( scaleTarget:Number, rate:Number, target:Spatial ):void
		{
			var camera:Camera = _cameraEntity.get( Camera );
			var targetSpatial:TargetSpatial = _cameraEntity.get( TargetSpatial );
			
			camera.scaleTarget = scaleTarget;
			camera.rate = rate;
			targetSpatial.target = target;
		}
		
		private function restoreZoom( zoneId:String = null, colliderId:String = null ):void
		{
			if( !shellApi.checkEvent( _events.DAM_DRAINED ) && !_firstHit )
			{
				Zone(getEntityById( "battleZone" ).get(Zone)).entered.add( reEnterBattle );
			}
			setCameraZoom( _defaultCameraZoom, .2, player.get( Spatial ));
		}
		
		private function reEnterBattle( zoneId:String = null, colliderId:String = null ):void
		{
			setCameraZoom( .75, .025, _zoomSpatial );
		}
		
		private function endPuzzle():void
		{
			var camera:Camera = _cameraEntity.get( Camera );
			var dialog:Dialog = player.get( Dialog );
			
			setCameraZoom( _defaultCameraZoom, .2, player.get( Spatial ));
			shellApi.triggerEvent( _events.DAM_DRAINED, true );
			
			dialog.sayById( "wonPuzzle" );
			dialog.complete.add( renewedPurpose );
			
			DamControlSystem(getSystem(DamControlSystem)).drainRate = 50;
			
			var entity:Entity = getEntityById( "beaverWalls" );
			removeEntity( entity );
			
			var battleZoneEntity:Entity = getEntityById( "battleZone" );
			var battleZone:Zone = battleZoneEntity.get(Zone);
			battleZone.entered.removeAll();
			battleZone.exitted.removeAll();
			removeEntity( battleZoneEntity );
			
			for( var i:int = 1; i < 6; i++ )
			{
				if(i < 4)
				{
					removeEntity(getEntityById("hole"+i));
				}
				var weed:Entity = getEntityById("weed"+i);
				if(weed != null)
				{
					var weedSpatial:Spatial = weed.get(Spatial);
					TweenUtils.entityTo(weed, Spatial, 2, {scaleY:-1, y:weedSpatial.y + weedSpatial.height, ease:Linear.easeNone});
				}
			}

			SceneUtil.addTimedEvent(this, new TimedEvent(5, 1, removePuzzleEntities));
		}
		
		/**
		 * Remove Entities used by beaver puzzle 
		 */
		private function removePuzzleEntities():void
		{
			// remove water
			removeEntity(getEntityById("waterHit"));
			
			// remove logs
			for( var number:int = 1; number < 4; number ++ )
			{
				_hitContainer.removeChild(  _hitContainer[ "underHit" + number ] );
				removeEntity( getEntityById( "floatingLogHit" + number ) )
				removeEntity( getEntityById( "floatingLog" + number ) );
			}
			
			// remove beavers
			super.removeEntity( super.getEntityById( "beaver1" ) );
			super.removeEntity( super.getEntityById( "beaver2" ) );
		}

		
	}
}
