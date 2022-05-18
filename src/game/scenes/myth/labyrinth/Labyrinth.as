package game.scenes.myth.labyrinth
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.components.SpatialAddition;
	import engine.components.Tween;
	import engine.creators.InteractionCreator;
	import engine.util.Command;
	
	import game.components.Emitter;
	import game.components.entity.Sleep;
	import game.components.motion.ShakeMotion;
	import game.components.motion.WaveMotion;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.Timeline;
	import game.creators.entity.EmitterCreator;
	import game.creators.scene.HitCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.WaveMotionData;
	import game.data.scene.hit.HitType;
	import game.particles.FlameCreator;
	import game.scenes.myth.labyrinth.components.ScorpionComponent;
	import game.scenes.myth.labyrinth.components.ThreadComponent;
	import game.scenes.myth.labyrinth.popups.Bones;
	import game.scenes.myth.labyrinth.systems.GoldenThreadSystem;
	import game.scenes.myth.labyrinth.systems.ScorpionSystem;
	import game.scenes.myth.shared.Athena;
	import game.scenes.myth.shared.MythScene;
	import game.systems.SystemPriorities;
	import game.systems.motion.ShakeMotionSystem;
	import game.systems.motion.WaveMotionSystem;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.PlatformUtils;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	
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
	
	public class Labyrinth extends MythScene
	{
		public function Labyrinth()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/myth/labyrinth/";
			
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
			
			addLight( player );
			
			var clip:MovieClip = _hitContainer[ "bonesPuzzle" ];
			
			if( shellApi.checkEvent( _events.COMPLETED_BONES ))
			{
				_hitContainer.removeChild( clip );
			}
			
			else
			{
				var entity:Entity = EntityUtils.createSpatialEntity( this, clip );
				var hitCreator:HitCreator = new HitCreator();
				
				hitCreator.makeHit( entity, HitType.WALL );
				entity.add( new Id( "puzzleBlock" ));
				_audioGroup.addAudioToEntity( entity );
				
				ToolTipCreator.addToEntity( entity );
				
				InteractionCreator.addToEntity( entity, [ InteractionCreator.CLICK ]);
				var sceneInteraction:SceneInteraction = new SceneInteraction();
				sceneInteraction.offsetX = 120;
				sceneInteraction.reached.add( showPopup );
				entity.add( sceneInteraction );
			}
			shellApi.eventTriggered.add( eventTriggers );
			
			setupTorches();
			phantomPan();
			setupScorpion();
						
			addSystem( new ScorpionSystem(), SystemPriorities.update );
			addSystem( new WaveMotionSystem(), SystemPriorities.move );
			
			if( PlatformUtils.isDesktop )
			{
				var timestamp:Number = 1/4;
				
				addSystem( new GoldenThreadSystem( timestamp ), SystemPriorities.update );
				SceneUtil.addTimedEvent( this, new TimedEvent( .5, 1, loadAthena ));
			
				CharUtils.lockControls( player );
			}
		}
		
		/**
		 * 
		 * ATHENA POPUP AND GOLD THREAD 
		 * 
		 */
		private function loadAthena():void
		{
			shellApi.logWWW( "got golden thread, calling athena now" );
			
			var popup:Athena = addChildGroup( new Athena( overlayContainer )) as Athena;
			popup.closeClicked.add( getGoldenThread );
			popup.id = "athena";
		}
		
		private function getGoldenThread( popup:Athena ):void
		{
			var entity:Entity;
			CharUtils.lockControls( player, false, false );
			entity = EntityUtils.createSpatialEntity( this, _hitContainer[ "goldenThread" ]);
			
			var display:Display = entity.get( Display );
			var sprite:Sprite = new Sprite();
			sprite.name = "trail";
			display.displayObject.addChild( sprite );
		
			var thread:ThreadComponent = new ThreadComponent();
			thread.trail = sprite;
			thread.lastX = player.get( Spatial ).x;
			thread.lastY = player.get( Spatial ).y;
			
			entity.add( thread );
		}
		
		private function eventTriggers( event:String, save:Boolean = true, init:Boolean = false, removeEvent:String = null ):void
		{
			if( event == _events.COMPLETED_BONES )
			{
				SceneUtil.lockInput( this );
				SceneUtil.addTimedEvent( this, new TimedEvent( .2, 1, openGate ));
			}
		}
		
		/** 
		 * 
		 *  BONES PUZZLE 
		 * 
		 */
		private function showPopup( character:Entity, interactionEntity:Entity ):void
		{
			var popup:Bones = addChildGroup( new Bones( overlayContainer )) as Bones;
			popup.id = "bones";
			
			popup.complete.add( Command.create( completeBones, popup ));	
		}
		
		private function completeBones( popup:Bones ):void
		{
			var entity:Entity = getEntityById( "puzzleBlock" );
			entity.remove( Interaction );
			popup.close();
			
			super.shellApi.triggerEvent( _events.COMPLETED_BONES, true );
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
			var entity:Entity = getEntityById( "puzzleBlock" );
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
			
			EmitterCreator.create( this, _hitContainer[ "smokeContainer" ], emitter, 0, 0, null, "smokeEmitter" );
		}
		
		private function shakeWall( counter:int, entity:Entity ):void
		{
			var shake:ShakeMotion = entity.get( ShakeMotion );
			var newCount:int = counter - 1;
			var smoke:Entity = getEntityById( "smokeEmitter" );
			var emitter:Emitter2D = smoke.get( Emitter ).emitter;
			ShakeMotionSystem( addSystem( new ShakeMotionSystem() )).configEntity( entity );
					
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
			tween.to( spatial, 2, { y : 130, onComplete : pathOpen, onCompleteParams : [ entity ]});
			
			entity.add( tween );
		}
		
		private function pathOpen( entity ):void
		{			
			removeEntity( getEntityById( "smokeEmitter" ));
			removeEntity( entity );
			SceneUtil.lockInput( this, false );
		}
		
		/**
		 * 
		 * PAN
		 * 
		 */
		private function phantomPan():void
		{
			var entity:Entity = getEntityById( "pan" );
			var display:Display = EntityUtils.getDisplay( entity );
			display.alpha = 0.3;
			
			_hitContainer.swapChildren( display.displayObject, _hitContainer[ "panContainer" ]);
			
			CharUtils.setPartColor( entity, CharUtils.LEG_FRONT, 0xffffff );
			CharUtils.setPartColor( entity, CharUtils.LEG_BACK, 0xffffff );
		}
		
		/**
		 * 
		 * TORCHES
		 * 
		 */
		
		private function setupTorches():void
		{
			_flameCreator = new FlameCreator();
			_flameCreator.setup( this, _hitContainer[ "flame1" ], null, onFlameLoaded );
		}
		
		private function onFlameLoaded():void
		{
			var clip:MovieClip;
			var i:uint = 1;
			for( i = 1; i < 3; i ++ )
			{
				clip = super._hitContainer[ "flame" + i ];
				_flameCreator.createFlame( this, clip, true );
			}
		}
		
		/**
		 * 
		 * SCORPION
		 * 
		 */
		private function setupScorpion():void
		{
			var scorpion:Entity = getEntityById( "scorpion" );
			var clip:MovieClip = EntityUtils.getDisplayObject( scorpion ) as MovieClip;
			var timeline:Timeline = TimelineUtils.convertClip( clip.tail, this, null, scorpion ).get( Timeline );
			timeline.paused = true;
			_audioGroup.addAudioToEntity( scorpion );
			var wave:WaveMotion = new WaveMotion();
			wave.add( new WaveMotionData( "y", 1.5, 50 ));
			scorpion.add( wave ).add( new SpatialAddition());
			
			var hit:Entity = getEntityById( "scorpionHit" );
			hit.add( new Motion()).remove( Sleep );
			hit.add( new ScorpionComponent( scorpion ));
			hit.add( timeline);
		}
		
		private var _flameCreator:FlameCreator;
		private static const RANDOM:String	=		"random";
//		private static const TORCH:String =			"torch_fire_01_L.mp3";
	}
}