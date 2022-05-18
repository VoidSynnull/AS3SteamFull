package game.scenes.myth.labyrinthSnake
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Id;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.systems.TweenSystem;
	import engine.util.Command;
	
	import game.components.Emitter;
	import game.components.motion.ShakeMotion;
	import game.components.render.Light;
	import game.components.scene.SceneInteraction;
	import game.creators.entity.EmitterCreator;
	import game.data.TimedEvent;
	import game.particles.FlameCreator;
	import game.scenes.myth.labyrinthSnake.popups.Snake;
	import game.scenes.myth.shared.MythScene;
	import game.systems.SystemPriorities;
	import game.systems.motion.ShakeMotionSystem;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.Fade;
	import org.flintparticles.common.actions.ScaleImage;
	import org.flintparticles.common.counters.Random;
	import org.flintparticles.common.displayObjects.Blob;
	import org.flintparticles.common.easing.Quadratic;
	import org.flintparticles.common.initializers.AlphaInit;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.RandomDrift;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.EllipseZone;
	import org.flintparticles.twoD.zones.LineZone;
	import org.flintparticles.twoD.zones.RectangleZone;
	
	public class LabyrinthSnake extends MythScene
	{
		public function LabyrinthSnake()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/myth/labyrinthSnake/";
			
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
			
			var entity:Entity;
			super.addSystem( new TweenSystem(), SystemPriorities.update );
			
			entity = EntityUtils.createSpatialEntity( this, _hitContainer[ "pillar" ] );
			entity.add( new Id( "puzzleBlock" ));
		
			if( super.shellApi.checkEvent( _events.COMPLETED_LABYRINTH ))
			{
				super.removeEntity( super.getEntityById( "interactionSnake" ));
			 	Spatial( entity.get( Spatial )).y = -105;
				
				super.removeEntity( super.getEntityById( "wallHit" ));
			}
			else
			{
				_audioGroup.addAudioToEntity( entity );
				SceneInteraction( super.getEntityById( "interactionSnake" ).get( SceneInteraction )).reached.add( showPopup );
			}
			
			addLight( player );
			super.shellApi.eventTriggered.add( eventTriggers );
			setupTorches();
		}
		
		// process incoming events
		private function eventTriggers( event:String, save:Boolean = true, init:Boolean = false, removeEvent:String = null ):void
		{
			var entity:Entity;
						
			if( event == _events.COMPLETED_LABYRINTH )
			{
				SceneUtil.setCameraTarget( this, super.getEntityById( "puzzleBlock" ));
				
				entity = super.getEntityById("lightOverlay");
				var light:Light = player.get( Light );
				player.remove( Light );
				super.getEntityById( "puzzleBlock" ).add( light );
				
				SceneUtil.addTimedEvent( this, new TimedEvent( 1, 1, openGate ));
			}
		}
		
		private function openGate():void
		{
			var entity:Entity = super.getEntityById( "puzzleBlock" );
						
			var shake:ShakeMotion = new ShakeMotion( new RectangleZone( -10, -2, 10, 2 ));
			entity.add( shake );
			
			startSmoke();
			shakeWall( 15, entity );
			super.shellApi.triggerEvent( "raise_wall" );
		}	
		
		private function startSmoke():void
		{
			var entity:Entity = super.getEntityById( "puzzleBlock" );
			var emitter:Emitter2D = new Emitter2D();
			
			emitter.counter = new Random( 50, 60 );
			emitter.addInitializer( new ImageClass( Blob, [10, 0xEEEEEE], true ) );
			emitter.addInitializer( new AlphaInit( .6, .7 ));
			emitter.addInitializer( new Lifetime( .5, 1 )); 
			emitter.addInitializer( new Velocity( new LineZone( new Point( -75, -10), new Point( 75, -15 ))));
			emitter.addInitializer( new Position( new EllipseZone( new Point( 0, 0 ), 50, 2 )));
			
			emitter.addAction( new Age( Quadratic.easeOut ));
			emitter.addAction( new Move());
			emitter.addAction( new RandomDrift( 100, 100 ));
			emitter.addAction( new ScaleImage( .7, 1.5 ));
			emitter.addAction( new Fade( .7, 0 ));
			emitter.addAction( new Accelerate( 0, -10 ));
			
			EmitterCreator.create( this, super._hitContainer[ "smokeContainer" ], emitter, 0, 0, null, "smokeEmitter" );
		}
		
		private function shakeWall( counter:int, entity:Entity ):void
		{
			var shake:ShakeMotion = entity.get( ShakeMotion );
			var newCount:int = counter - 1;
			var smoke:Entity = super.getEntityById( "smokeEmitter" );
			var emitter:Emitter2D = smoke.get( Emitter ).emitter;
			ShakeMotionSystem( super.addSystem( new ShakeMotionSystem() )).configEntity( entity );
			
			if ( counter > 0 )
			{
				emitter.counter = new Random( newCount, newCount + 10 );
				SceneUtil.addTimedEvent( this, new TimedEvent( .04, 1, Command.create( shakeWall, newCount, entity )));
			}
				
			else
			{
				shake.shakeZone = new RectangleZone( 0, 0, 0, 0 );
				SceneUtil.addTimedEvent( this, new TimedEvent( 1, 1, Command.create( upTween, entity )));
			}
		}
		
		private function upTween( entity:Entity ):void
		{
			var spatial:Spatial = entity.get( Spatial );
			
			var tween:Tween = new Tween();
			tween.to( spatial, 2, { y : -105, onComplete : pathOpen });
			
			entity.add( tween );
		}
		
		private function pathOpen():void
		{			
			super.removeEntity( super.getEntityById( "interactionSnake" ));
			super.removeEntity( super.getEntityById( "wallHit" ));
			super.removeEntity( super.getEntityById( "smokeEmitter" ));
			
			SceneUtil.lockInput( this, false );
			SceneUtil.setCameraTarget( this, player );
			
			var light:Light = getEntityById( "puzzleBlock" ).get( Light );
			getEntityById( "puzzleBlock" ).remove( Light );
			player.add( light );
		}
		
		private function showPopup( character:Entity, interactionEntity:Entity ):void
		{
			var popup:Snake = super.addChildGroup( new Snake( super.overlayContainer )) as Snake;
			popup.id = "snake";
			
			popup.complete.add( Command.create( completeSnake, popup ));
		}
		
		private function completeSnake( popup:Snake ):void
		{
			popup.close();
			super.shellApi.triggerEvent( _events.COMPLETED_LABYRINTH, true );
		}
		
		private function setupTorches():void
		{
			_flameCreator = new FlameCreator();
			_flameCreator.setup( this, _hitContainer[ "flame1" ], null, onFlameLoaded );
		}
		
		private function onFlameLoaded():void
		{
			var clip:MovieClip;
			var i:uint = 1;
			for( i = 1; i < 4; i ++ )
			{
				clip = super._hitContainer[ "flame" + i ];
				_flameCreator.createFlame( this, clip, true );
			}
		}
		
		private var _flameCreator:FlameCreator;
		private static const RANDOM:String	=		"random";
	}
}