package game.scenes.myth.riverStyx
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.components.SpatialAddition;
	
	import game.components.entity.Sleep;
	import game.components.motion.FollowTarget;
	import game.components.motion.Threshold;
	import game.components.motion.WaveMotion;
	import game.components.scene.SceneInteraction;
	import game.creators.entity.EmitterCreator;
	import game.creators.scene.HitCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.WaveMotionData;
	import game.data.display.BitmapWrapper;
	import game.data.scene.hit.HitType;
	import game.data.scene.hit.MovingHitData;
	import game.data.scene.hit.WaterHitData;
	import game.particles.FlameCreator;
	import game.scenes.myth.cerberus.Cerberus;
	import game.scenes.myth.riverStyx.components.StyxComponent;
	import game.scenes.myth.riverStyx.popups.LoseStyx;
	import game.scenes.myth.riverStyx.systems.StyxSystem;
	import game.scenes.myth.shared.MythScene;
	import game.systems.ParticleSystem;
	import game.systems.SystemPriorities;
	import game.systems.hit.WaterHitSystem;
	import game.systems.motion.FollowTargetSystem;
	import game.systems.motion.ThresholdSystem;
	import game.systems.motion.WaveMotionSystem;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.PerformanceUtils;
	import game.util.PlatformUtils;
	import game.util.SceneUtil;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.Fade;
	import org.flintparticles.common.actions.ScaleImage;
	import org.flintparticles.common.counters.Blast;
	import org.flintparticles.common.displayObjects.Blob;
	import org.flintparticles.common.initializers.ColorInit;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.RectangleZone;
	
	public class RiverStyx extends MythScene
	{
		public function RiverStyx()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/myth/riverStyx/";
			
			super.init(container);
		}
		
		override public function destroy():void
		{
			_flameCreator.destroy();
			super.destroy();
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
			//super.shellApi.screenManager.setSizeTwo();
			 
			setupBoat();
			
			var boatHit:Entity = getEntityById( "boatHit" );
			var boatMotion:Motion = boatHit.get( Motion );
			var boatHitSpatial:Spatial = boatHit.get( Spatial );
			
			var point:Point = DisplayUtils.localToLocalPoint(new Point(boatHitSpatial.width-super.shellApi.viewportWidth/6, 400), _hitContainer.stage, _hitContainer);
			
			// USE A CAMERA ENTITY INSTEAD OF THE BOAT HIT
			var cameraEntity:Entity = new Entity();
			var followTarget:FollowTarget = new FollowTarget( boatHitSpatial, 1 );
			followTarget.offset = point;
			
			var spatial:Spatial = new Spatial( boatHitSpatial.x + point.x, 400 );
			cameraEntity.add( followTarget ).add( spatial );
			addEntity( cameraEntity );
			
			SceneUtil.setCameraTarget( this, cameraEntity, true );
			
			var styxSystem:StyxSystem = new StyxSystem( boatMotion );
			styxSystem.finished.addOnce( stopThePuzzle );
			
			addSystem( new FollowTargetSystem());
			addSystem( styxSystem, SystemPriorities.move );
			addSystem( new WaveMotionSystem());
			addSystem( new ThresholdSystem());
			
			var waterHit:WaterHitSystem = new WaterHitSystem();
			waterHit.playerWeight = PLAYER_WEIGHT;
			addSystem( waterHit );
			addSystem( new ParticleSystem());
			
			setupHazards();
			EntityUtils.position( player, 170, 380 );
			
			
		}
		
		private function setupBoat():void
		{
			// REMOVE CHARON'S TOOLTIP
			var charon:Entity = super.getEntityById( "charon" );
			ToolTipCreator.removeFromEntity( charon );
			charon.remove( Interaction );
			charon.remove( SceneInteraction );
			
			var display:Display = charon.get( Display );
			display.container.mouseChildren = false;

			var boatHit:Entity = getEntityById( "boatHit" );
			display = boatHit.get( Display );
			display.alpha = 0;
			
			var spatial:Spatial = boatHit.get( Spatial );
			var clip:DisplayObject = _hitContainer[ "boat" ];
			if( PlatformUtils.isMobileOS )
			{
				super.convertContainer( clip, PerformanceUtils.defaultBitmapQuality * 2 );
			}
			var boat:Entity = EntityUtils.createSpatialEntity( this, clip, _hitContainer );
			var followTarget:FollowTarget = new FollowTarget( spatial, 1, false, true );
			boat.add( followTarget );
			display = boat.get( Display );
			display.container.mouseChildren = false;
			
			
			// MOVE BOAT ABOVE PLAYER AND CHARON 
			var displayObject:DisplayObject = EntityUtils.getDisplayObject( boat );
			_hitContainer.setChildIndex( displayObject, _hitContainer.numChildren - 1 );
			
			// STICK CHARON TO BOAT
			EntityUtils.followTarget( charon, boatHit, 1, new Point( 50, -50 )); 

			
			// ADD WAVE MOTION TO THE BOAT
			var spatialAddition:SpatialAddition = new SpatialAddition(); 
			var waveMotion:WaveMotion = new WaveMotion();
			var waveMotionData:WaveMotionData = new WaveMotionData();
			
			waveMotionData.property = "rotation";
			waveMotionData.magnitude = 1.5;
			waveMotionData.rate = .05;
			waveMotionData.radians = 0;
			waveMotion.data.push( waveMotionData );
			
			boat.add( waveMotion );
			boat.add( spatialAddition );
			boat.add( new Id( clip.name ));
			
			// WATER 
			var water:Entity = EntityUtils.createSpatialEntity( this, _hitContainer[ "aqua" ]);
			display = water.get( Display );
			display.alpha = 0;
			
			// ADD MOTION TO THE BOAT
			var motion:Motion = new Motion();
			motion.velocity = new Point( BOAT_VELOCITY, 0 );
			water.add( new Id( "water" )).add( motion ).add( new Sleep( false, true ));
			
			// ADD HIT COMPONENTS TO WATER
			var waterHitData:WaterHitData = new WaterHitData();
			waterHitData.density = WATER_DENSITY;
			waterHitData.viscosity = WATER_VISCOSITY;
			waterHitData.splashColor1 = 0xFF339900;
			waterHitData.splashColor2 = 0x33ccff33;
			
//			var moverHitData:MoverHitData = new MoverHitData();
//			moverHitData.stickToPlatforms = true;
			
			var hitCreator:HitCreator = new HitCreator();
			hitCreator.makeHit( water, HitType.WATER, waterHitData );
			hitCreator.addHitSoundsToEntity( water, _audioGroup.audioData, shellApi );
	//		hitCreator.makeHit( water, HitType.MOVER, moverHitData );
			
			// ADD PLAYER THRESHOLD
			var threshold:Threshold = new Threshold( "y", ">" );
			threshold.threshold = 450;
			threshold.entered.add( fellIn );
			player.add( threshold );
			
			// START BOAT
			motion = boatHit.get( Motion );
			boatHit.remove( MovingHitData );
			motion.velocity.x = BOAT_VELOCITY;
		}
		
		private function setupHazards():void
		{
			var audio:Audio;
			var audioRange:AudioRange;
			var clip:MovieClip;
			var croc:Entity;
			var display:Display;
			var displayObject:DisplayObject;
			var displayObjectBounds:Rectangle;
			var flames:Array;
			var flameEnt:Entity;
			var hit:Entity;
			var sleep:Sleep;
			var soul:Entity;
			var spatial:Spatial;
			var stalac:Entity;
			var styx:StyxComponent;
			
			var wrapper:BitmapWrapper;
			var sprite:Sprite;
			var bitmapData:BitmapData;
			var bitmap:Bitmap;
			var offsetMatrix:Matrix;
			
			for( var j:Number = 0; j < 3; j++ )
			{
				switch( j )
				{
					case 0:
						hit = getEntityById( "stalacHit" );
						spatial = hit.get( Spatial );
						spatial.scale = .6;
						spatial.x = -100;
						spatial.y = -100;
						
						styx = new StyxComponent();
						
						audioRange = new AudioRange( 600, .01, 1 );
						clip = _hitContainer[ "stalac" ];
						wrapper = this.convertToBitmapSprite( clip );
						displayObjectBounds = clip.getBounds( clip );
						offsetMatrix = new Matrix( 1, 0, 0, 1, displayObjectBounds.left, displayObjectBounds.top );
						
						sprite = new Sprite();
						
						bitmapData = new BitmapData( displayObjectBounds.width, displayObjectBounds.height, true, 0x000000 );
						bitmapData.draw( wrapper.data, null );
						
						bitmap = new Bitmap( bitmapData, "auto", true );
						bitmap.transform.matrix = offsetMatrix;
						sprite.addChild( bitmap );
						sprite.mouseChildren = false;
						sprite.mouseEnabled = false;					
						
						stalac = EntityUtils.createSpatialEntity( this, sprite, _hitContainer );
						stalac.add( new FollowTarget( spatial, 1, false, true ));
						
						spatial = stalac.get( Spatial );
						spatial.scale = .6;
						
						styx.origin = STALAC_ORIGIN;
						addSplash( styx );
						display = hit.get( Display );
						display.alpha = 0;
						sleep = hit.get( Sleep );
						sleep.sleeping = false;
//						sleep.ignoreOffscreenSleep = true;
						hit.add( new SpatialAddition()).add( audioRange ).add( styx ).add( new Motion());
						_audioGroup.addAudioToEntity( hit );
						
						displayObject = EntityUtils.getDisplayObject( stalac );
						_hitContainer.setChildIndex( displayObject, _hitContainer.numChildren - 1 );
						
						styx.visual = stalac.get( Display );
						styx.visual.alpha = 0;
						
						stalac.add( sleep );
						break;
					
					case 1:
						hit = getEntityById( "soulHit" );
						spatial = hit.get( Spatial );
						spatial.x = -100;
						spatial.y = -100;
						styx = new StyxComponent();
												
						clip = _hitContainer[ "soul" ][ "flame" ];

						_flameCreator = new FlameCreator();
						_flameCreator.setup( this, clip, null, onFlameLoaded );
					
						
						clip = _hitContainer[ "soul" ][ "rect" ];
						wrapper = this.convertToBitmapSprite( clip[ "content" ]);
						displayObjectBounds = clip.getBounds( clip );
						offsetMatrix = new Matrix( 1, 0, 0, 1, displayObjectBounds.left, displayObjectBounds.top );
						
						sprite = new Sprite();
						
						bitmapData = new BitmapData( displayObjectBounds.width, displayObjectBounds.height, true, 0x000000 );
						bitmapData.draw( wrapper.data, null );
						
						bitmap = new Bitmap( bitmapData, "auto", true );
						bitmap.transform.matrix = offsetMatrix;
						sprite.addChild( bitmap );
						sprite.mouseChildren = false;
						sprite.mouseEnabled = false;
						
						soul = EntityUtils.createSpatialEntity( this, _hitContainer[ "soul" ]);
						soul.add( new FollowTarget( spatial, 1, false, true ));
						
						audioRange = new AudioRange( 600, .01, 1 );
						display = hit.get( Display );
						display.alpha = 0;
						
						sleep = hit.get( Sleep );
						sleep.sleeping = true;
			//			sleep.ignoreOffscreenSleep = true;
						styx.origin = SOUL_ORIGIN;
						hit.add( audioRange ).add( styx ).add( new Motion());
						_audioGroup.addAudioToEntity( hit );
						
						displayObject = EntityUtils.getDisplayObject( soul );
						_hitContainer.setChildIndex( displayObject, _hitContainer.numChildren - 1 );
					
						styx.visual = soul.get( Display );
						styx.visual.alpha = 0;
						
						soul.add( sleep );
						break;
					
					case 2:
						hit = getEntityById( "crocHit" );
						spatial = hit.get( Spatial );
						spatial.x = -100;
						spatial.y = -100;
						styx = new StyxComponent();
						
						audioRange = new AudioRange( 300, .01, 1 );
			
						// CROC BODY
						clip = _hitContainer[ "croc" ][ "body" ];
						styx.crocBody = clip;
						
						wrapper = this.convertToBitmapSprite( clip[ "content" ], null, true, 2 );
						displayObjectBounds = clip.getBounds( clip );
						offsetMatrix = new Matrix( 1, 0, 0, 1, displayObjectBounds.left, displayObjectBounds.top );
						
						sprite = new Sprite();
						
						bitmapData = new BitmapData( displayObjectBounds.width, displayObjectBounds.height, true, 0x000000 );
						bitmapData.draw( wrapper.data, null );
						
						bitmap = new Bitmap( bitmapData, "auto", true );
						bitmap.transform.matrix = offsetMatrix;
						sprite.addChild( bitmap );
						sprite.mouseChildren = false;
						sprite.mouseEnabled = false;
						
						// CROC TAIL
						clip = _hitContainer[ "croc" ][ "tail" ];
						wrapper = this.convertToBitmapSprite( clip[ "content" ], null, true, 2);
						displayObjectBounds = clip.getBounds( clip );
						offsetMatrix = new Matrix( 1, 0, 0, 1, displayObjectBounds.left, displayObjectBounds.top );
						
						sprite = new Sprite();
						
						bitmapData = new BitmapData( displayObjectBounds.width, displayObjectBounds.height, true, 0x000000 );
						bitmapData.draw( wrapper.data, null );
						
						bitmap = new Bitmap( bitmapData, "auto", true );
						bitmap.transform.matrix = offsetMatrix;
						sprite.addChild( bitmap );
						sprite.mouseChildren = false;
						sprite.mouseEnabled = false;
						
						// CROC HEAD
						clip = _hitContainer[ "croc" ][ "head" ];
						wrapper = this.convertToBitmapSprite( clip[ "topJaw" ], null, true, 2);
						displayObjectBounds = clip[ "topJaw" ].getBounds( clip[ "topJaw" ]);
						offsetMatrix = new Matrix( 1, 0, 0, 1, displayObjectBounds.left, displayObjectBounds.top );
						
						sprite = new Sprite();
						
						bitmapData = new BitmapData( displayObjectBounds.width, displayObjectBounds.height, true, 0x000000 );
						bitmapData.draw( wrapper.data, null );
						
						bitmap = new Bitmap( bitmapData, "auto", true );
						bitmap.transform.matrix = offsetMatrix;
						sprite.addChild( bitmap );
						sprite.mouseChildren = false;
						sprite.mouseEnabled = false;
						
						styx.crocJaw = clip[ "topJaw" ];
						
						// BOTTOM JAW
						wrapper = this.convertToBitmapSprite( clip[ "jaw" ], null, true, 2);
						displayObjectBounds = clip[ "jaw" ].getBounds( clip[ "jaw" ]);
						offsetMatrix = new Matrix( 1, 0, 0, 1, displayObjectBounds.left, displayObjectBounds.top );
						
						sprite = new Sprite();
						
						bitmapData = new BitmapData( displayObjectBounds.width, displayObjectBounds.height, true, 0x000000 );
						bitmapData.draw( wrapper.data, null );
						
						bitmap = new Bitmap( bitmapData, "auto", true );
						bitmap.transform.matrix = offsetMatrix;
						sprite.addChild( bitmap );
						sprite.mouseChildren = false;
						sprite.mouseEnabled = false;
						
						croc = EntityUtils.createSpatialEntity( this, _hitContainer[ "croc" ]);
						croc.add( new FollowTarget( spatial, 1, false, false ));
						
						styx.origin = CROC_ORIGIN;
						addSplash( styx );
						display = hit.get( Display );
						display.alpha = 0;
						sleep = hit.get( Sleep );
						sleep.sleeping = true;
			//			sleep.ignoreOffscreenSleep = true;
						hit.add( audioRange ).add( styx ).add( new Motion());
						_audioGroup.addAudioToEntity( hit );
						
						styx.visual = croc.get( Display );
						styx.visual.alpha = 0;
						
						croc.add( sleep );
						
						displayObject = EntityUtils.getDisplayObject( croc );
						_hitContainer.setChildIndex( displayObject, _hitContainer.numChildren - 1 );
						break;
				}
			}
		}
		
		private function onFlameLoaded():void
		{
			var asset:MovieClip;
			var clip:MovieClip;
			var i:uint = 1;
			
			
			asset = _hitContainer[ "soul" ][ "flame" ];
			_flameCreator.createFlame( this, asset, true );
		}
		
		
		private function addSplash( styx:StyxComponent ):void
		{
			var splash:Emitter2D = new Emitter2D();
			var splashEnt:Entity;
			
			splash.stop();
			splash.counter = new Blast( 30 );
			
			splash.addInitializer( new ImageClass( Blob, [ 8 ], true ));
			splash.addInitializer( new Lifetime( 1 ));
			splash.addInitializer( new ColorInit( 0xFF339900, 0x33ccff33 ));
			
			splash.addInitializer( new Velocity( new RectangleZone( -90, -200, 90, -100 )));
			
			splash.addAction( new Move());	
			splash.addAction( new Fade( 1, 0 ));			
			splash.addAction( new ScaleImage( .5, .25 ));	
			splash.addAction( new Age());
			splash.addAction( new Accelerate( 0, 75 ));
			
			splashEnt = EmitterCreator.create( this, _hitContainer, splash );
			styx.splashEmitter = splash;
		}

		/*******************************
		 * 	   FELL IN RIVER STYX
		 * *****************************/
		private function fellIn():void
		{
			var popup:LoseStyx = addChildGroup( new LoseStyx( super.overlayContainer )) as LoseStyx;
			popup.id = "loseStyx";
		}
		
		private function stopThePuzzle():void
		{
			var shore:Entity = EntityUtils.createSpatialEntity( this, _hitContainer[ "shore" ]);
			shore.add( new Id( "shore" ));
			var motion:Motion = player.get( Motion );
			EntityUtils.position( shore, motion.x + shellApi.viewportWidth, 400 );
			
			var boatHit:Entity = getEntityById( "boatHit" );
			var threshold:Threshold = boatHit.get( Threshold );
			
			if( !threshold )
			{
				threshold = new Threshold( "x", ">" );
				boatHit.add( threshold );
			}
			
			threshold.threshold = motion.x + .5 * shellApi.viewportWidth;
			threshold.entered.addOnce( dockBoat );
			
			motion = boatHit.get( Motion );
			motion.acceleration.x = -15;
			motion.minVelocity.x = 5;
			CharUtils.lockControls( player );
		}
		
		private function dockBoat():void
		{
			var creator:HitCreator = new HitCreator();
			var shore:Entity = getEntityById( "shore" );

			var boatHit:Entity = getEntityById( "boatHit" );
			boatHit.remove( Threshold );
			
			
			var motion:Motion = boatHit.get( Motion );
			motion.velocity.x = 0;
			motion.acceleration.x = 0;
			motion.previousAcceleration.x = 0;
			
			faceCerberus();
		}
		
		private function faceCerberus():void
		{
			super.shellApi.loadScene( Cerberus );
		}
		
		private var _flameCreator:FlameCreator;
		private var CROC_ORIGIN:Point = new Point( 900, 470 );
		private var SOUL_ORIGIN:Point =  new Point( 1000, 200 );
		private var STALAC_ORIGIN:Point = new Point( 0, -25);

		private const WATER_DENSITY:Number 	= 1;
		private const WATER_VISCOSITY:Number = .9;
		private const PLAYER_WEIGHT:Number = .05;
		
	
		private static const STYX_STOPS_THRESHOLD:Number =   7900; 
		private static const BOAT_VELOCITY:Number = 		175;
	}
}