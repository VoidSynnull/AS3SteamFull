package game.scenes.carrot.computer
{
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.MotionBounds;
	import engine.components.Spatial;
	import engine.group.Scene;
	
	import game.components.motion.Edge;
	import game.components.Emitter;
	import game.components.motion.SpatialToMouse;
	import game.components.motion.RotateControl;
	import game.components.motion.ShakeMotion;
	import game.creators.entity.EmitterCreator;
	import game.data.TimedEvent;
	import game.scenes.carrot.computer.components.Asteroid;
	import game.scenes.carrot.computer.components.Rabbot;
	import game.scenes.carrot.computer.particles.PixelCollision;
	import game.scenes.carrot.computer.particles.PixelExhaust;
	import game.scenes.carrot.computer.particles.PixelStarfield;
	import game.scenes.carrot.computer.systems.AsteroidSystem;
	import game.scenes.carrot.computer.systems.RabbotSystem;
	import game.systems.motion.BoundsCheckSystem;
	import game.systems.motion.SpatialToMouseSystem;
	import game.systems.SystemPriorities;
	import game.systems.motion.RotateToTargetSystem;
	import game.systems.motion.ShakeMotionSystem;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	
	import org.flintparticles.twoD.zones.DiscZone;
	import org.flintparticles.twoD.zones.LineZone;
	import org.osflash.signals.Signal;

	/**
	 * ...
	 * @author Bard
	 * 
	 * Asteroid Game. The pixelly game that's played on the Computer console.
	 */
	
	public class AsteroidGame
	{
		
		public function AsteroidGame( scene:Scene, screen:MovieClip )
		{
			_scene = scene;
			_screen = screen;
			
			init();
		}
		
		private function init( ):void 	
		{
			hitSignal = new Signal();
			destroyed = new Signal();
			complete = new Signal();
			
			_screenLayer = _screen.content.screenLayer;
			_screenMask = _screen.content.screenMask;
		}
		
		public function start():void
		{
			// create rabbot
			initRabbot();
			
			// create asteroid
			initAsteroid();
			
			// initJoystick
			initJoystick();	// start joystick response		
			
			// create pixel exhaust effect
			var exhaust:PixelExhaust = new PixelExhaust();
			var positionZone:LineZone = new LineZone( new Point( -PIXEL_SIZE * 3, 0), new Point( PIXEL_SIZE * 3, 0 ) );
			exhaust.init( PIXEL_SIZE, 0xF5A30A, 250, positionZone, _screenMask );
			_emitterExhaust = EmitterCreator.create( _scene, _screenLayer, exhaust, 0, 0, _rabbot, "pixelExhaust", _rabbot.get(Spatial)).get( Emitter );
			
			// create starfield effect
			var starfield:PixelStarfield = new PixelStarfield();
			positionZone = new LineZone( new Point( 0, 0), new Point( _screenMask.width, 0 ) );
			var starContainer:Sprite = new Sprite();
			_screenLayer.addChildAt( starContainer, 0 );
			starfield.init( PIXEL_SIZE, 0xCDFAFC, 400, positionZone, _screenMask );
			_emitterStarfield = EmitterCreator.create( _scene, starContainer, starfield, 0, 0, null, "starfield").get( Emitter );
			
			// create collision effect
			var collision:PixelCollision = new PixelCollision();
			var velocityZone:DiscZone = new DiscZone( null, 200, 150 );
			collision.init( PIXEL_SIZE, 12, velocityZone, _screenMask );
			_emitterCollision = EmitterCreator.create( _scene, _screenLayer, collision, 0, 0, null, "collision", null, false );
		}

		private function onCollision():void
		{
			// increment and dispatch hit
			
			_hitCount++;
			hitSignal.dispatch(_hitCount);
			
			// play collision effect
			EntityUtils.positionByEntity( _emitterCollision, _asteroid );
			Emitter(_emitterCollision.get( Emitter )).start = true;
			
			// TODO :: apply transition to rabbot y, to make it bob, move down and back up
			
			if ( _hitCount == HIT_MAX )
			{
				// start _rabbot shake
				Motion(_rabbot.get(Motion)).velocity.x = 0;
				_rabbot.remove(Rabbot);	// remove controls
				
				_emitterStarfield.pause = true;			// pause starfield
				_emitterExhaust.emitter.counter.stop();	// stop exhaust emitter
				
				_rabbot.add( new ShakeMotion( new DiscZone( null, 5 ) ) );
				ShakeMotionSystem( _scene.addSystem( new ShakeMotionSystem() ) ).configEntity( _rabbot );
			}
		}
		
		public function unpause():void
		{
			if ( _hitCount < HIT_MAX )
			{
				Asteroid(_asteroid.get(Asteroid)).paused = false;
			}
			else
			{
				explode();
			}
		}
		
		private function explode():void
		{
			// init pixelhare
			_pixelHare = EntityUtils.createMovingEntity( _scene, _scene.getAsset("pixelHare.swf"), _screenLayer );
			var spatialHare:Spatial = EntityUtils.positionByEntity( _pixelHare, _rabbot );
			spatialHare.y -= Spatial(_rabbot.get(Spatial)).height / 2;
			
			var motion:Motion = _pixelHare.get(Motion);
			motion.velocity.y = -150;
			//motion.rotationVelocity = 20;	// TODO :: allow rotation to be set directly
			motion.rotationAcceleration = 350;
			motion.rotationMaxVelocity = 350;
			
			// create explosion
			var explosion:PixelCollision = new PixelCollision();
			var velocityZone:DiscZone = new DiscZone( null, 300, 150 );
			explosion.init( PIXEL_SIZE, 30, velocityZone, _screenMask );
			EmitterCreator.create( _scene, _screenLayer, explosion, spatialHare.x, spatialHare.y );
			
			// remove rabbot
			_scene.removeEntity( _rabbot );
			
			// add timer to signal complete
			destroyed.dispatch();
			SceneUtil.addTimedEvent( _scene, new TimedEvent( 2, 1, onComplete, true) );
		}
		
		private function onComplete():void
		{
			complete.dispatch();
		}
		
		private function initRabbot():void
		{
			_rabbot = EntityUtils.createMovingEntity( _scene, _scene.getAsset("rabbot.swf"), _screenLayer );
			EntityUtils.position( _rabbot, _screenMask.width / 2, _screenMask.height*.75 );
			
			_rabbot.add( EntityUtils.createTargetSpatial( _scene.shellApi.inputEntity ) );
			
			var motionBounds:MotionBounds = new MotionBounds();
			motionBounds.box = _screenMask.getBounds(_screenMask) as Rectangle;
			
			var edge:Edge = new Edge();
			edge.unscaled.right = Display(_rabbot.get(Display)).displayObject.width / 2;;
			edge.unscaled.left = -edge.unscaled.right;
			_rabbot.add( edge );
			_rabbot.add( motionBounds );
			_scene.addSystem( new BoundsCheckSystem(), SystemPriorities.moveComplete );
			
			var rabbot:Rabbot = new Rabbot();
			rabbot.screenCenter = _scene.shellApi.viewportWidth/2;
			rabbot.maxSpeed = VEL_MAX;
			rabbot.maxControlDelta = _screenMask.width / 2;
			_rabbot.add( rabbot );
			_scene.addSystem( new RabbotSystem(), SystemPriorities.update );
		}
		
		private function initAsteroid():void
		{
			_asteroid = EntityUtils.createMovingEntity( _scene, _scene.getAsset("asteroid.swf"), _screenLayer );
			Display(_asteroid.get(Display)).visible = false;
			
			var asteroid:Asteroid = new Asteroid();
			asteroid.bounds = _screenMask.getBounds( _screenMask );
			asteroid.minWaitTime = 2;
			asteroid.rangeWaitTime = 2;
			asteroid.target = MovieClip(Display(_rabbot.get(Display)).displayObject).content.hit;
			asteroid.velYMin = ASTEROID_VEL_MIN;
			asteroid.velYRange = ASTEROID_VEL_RANGE;
			asteroid.waitTime = 6;	// first wait is longer
			asteroid.hitSignal.add( onCollision );
			_asteroid.add( asteroid );
			_scene.addSystem( new AsteroidSystem(), SystemPriorities.update );		// TODO :: Shoudl we just make the priority 0 by default?
		}
		
		private function initJoystick():void
		{
			var entity:Entity = new Entity();
			_scene.addEntity(entity);
			
			entity.add(new Spatial());
			entity.add(new SpatialToMouse(_screen.content));
			_scene.addSystem(new SpatialToMouseSystem());
			
			var stickClip:MovieClip = _screen.content.stick;
			_joystickStick = EntityUtils.createSpatialEntity( _scene, stickClip );
			_joystickStick.add( EntityUtils.createTargetSpatial( entity ) );
			var rotateControl:RotateControl = new RotateControl();
			rotateControl.setRange( JOYSTICK_MIN, JOYSTICK_MAX );
			//rotateControl.adjustForViewportScale = false;
			_joystickStick.add( rotateControl );
			_scene.addSystem( new RotateToTargetSystem );
		}
		
		private const ASTEROID_VEL_MIN:int = 225;
		private const ASTEROID_VEL_RANGE:int = 50;
		private const JOYSTICK_MIN:int = -150;//-60
		private const JOYSTICK_MAX:int = -30;//60
		private const VEL_MAX:int = 250;
		private const HIT_MAX:int = 4;
		private const PIXEL_SIZE:int = 6;
		
		public var hitSignal:Signal;
		public var destroyed:Signal;
		public var complete:Signal;
		
		private var _scene:Scene;
		private var _screen:MovieClip;
		
		private var _hitCount:int = 0;
		
		private var _screenLayer:MovieClip;
		private var _screenMask:MovieClip;
		
		private var _pixelHare:Entity;
		private var _rabbot:Entity;
		private var _asteroid:Entity;
		private var _joystickBall:Entity;
		private var _joystickStick:Entity;
		
		private var _emitterExhaust:Emitter;
		private var _emitterStarfield:Emitter;
		private var _emitterCollision:Entity;
		
	}
}