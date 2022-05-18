package game.scenes.myth.hadesPit1
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.components.SpatialAddition;
	import engine.creators.InteractionCreator;
	
	import game.components.entity.Dialog;
	import game.components.motion.Spring;
	import game.components.motion.Threshold;
	import game.components.motion.WaveMotion;
	import game.components.scene.SceneInteraction;
	import game.creators.entity.EmitterCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.WaveMotionData;
	import game.data.scene.characterDialog.DialogData;
	import game.particles.FlameCreator;
	import game.scenes.myth.hadesPit2.HadesPit2;
	import game.scenes.myth.shared.MythScene;
	import game.systems.SystemPriorities;
	import game.systems.motion.ThresholdSystem;
	import game.systems.motion.WaveMotionSystem;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.counters.Random;
	import org.flintparticles.common.displayObjects.Dot;
	import org.flintparticles.common.initializers.ColorInit;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.common.initializers.ScaleImageInit;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.RandomDrift;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.LineZone;
	
	public class HadesPit1 extends MythScene
	{
		public function HadesPit1()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/myth/hadesPit1/";
			
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
			super.addSystem( new ThresholdSystem(), SystemPriorities.update );
			super.addSystem( new WaveMotionSystem(), SystemPriorities.move );
			
			setupTorches();
			setBat();
		
			var threshold:Threshold = new Threshold( "y", ">" );
			threshold.threshold = super.sceneData.bounds.bottom - 200;
			threshold.entered.add( fallingTransition );
			super.player.add( threshold );
			
			super._hitContainer.swapChildren( Display( player.get( Display )).displayObject, super._hitContainer[ "playerEmpty" ]);
		
			var entity:Entity = super.getEntityById( "doorGate" );
			
			var sceneInteraction:SceneInteraction = entity.get( SceneInteraction );
			
			sceneInteraction.reached.removeAll();
			sceneInteraction.reached.add( doorLocked );
		}
		
		
		private function doorLocked( char:Entity, door:Entity ):void
		{
			SceneUtil.lockInput( this );
			Dialog( super.player.get( Dialog )).sayById( "door_locked" );
			Dialog( super.player.get( Dialog )).complete.add( unlockInput );
		}
		
		private function setupTorches():void
		{
			_flameCreator = new FlameCreator();
			_flameCreator.setup( this, _hitContainer[ "flame" ], null, onFlameLoaded );
		}
		
		private function onFlameLoaded():void
		{
			var clip:MovieClip;
			var i:uint = 1;
			clip = super._hitContainer[ "flame" ];
			_flameCreator.createFlame( this, clip, true );
		}
					
		private function fallingTransition():void
		{
			SceneUtil.lockInput( this );	
			
			var entity:Entity = new Entity();
			var emitter:Emitter2D;
			var clip:MovieClip
			
			clip = super._hitContainer[ "falling" ];
			emitter = new Emitter2D();
			
			emitter.counter = new Random( 15, 25 );
			
			emitter.addInitializer( new ImageClass( Dot, [1], true ));
			emitter.addInitializer( new Position( new LineZone( new Point( -850, 0 ), new Point( 850, 0 ))));
			emitter.addInitializer( new Velocity( new LineZone( new Point( 0, -800 ), new Point( 0, -1600 ))));
			emitter.addInitializer( new ScaleImageInit( 1, 4 ));
			emitter.addInitializer( new ColorInit( 0x01FFE9BD, 0xFFCBFFFF ));
			emitter.addInitializer( new Lifetime( 2 )); 
			
			emitter.addAction( new Age() );
			emitter.addAction( new Move() );
			emitter.addAction( new RandomDrift( 0, -800 ));
			emitter.addAction( new Accelerate( 0, -1600 ));
			
			entity = EmitterCreator.create( this, clip, emitter );
			
			SceneUtil.addTimedEvent( this, new TimedEvent( 5, 1, changeScene ));
		}
		
		private function setBat():void
		{
			var entity:Entity = EntityUtils.createMovingEntity( this, super._hitContainer[ "bat" ], super._hitContainer );
			for( var number:int = 1; number < 3; number ++ )
			{
				TimelineUtils.convertClip( MovieClip( MovieClip( EntityUtils.getDisplayObject( entity )).getChildByName( "wing" + number )), this, null, entity );
			}
			
			var interactions:Array;
			
			if ( !interactions )
			{
				interactions = [ InteractionCreator.UP, InteractionCreator.OVER, InteractionCreator.DOWN, InteractionCreator.OUT, InteractionCreator.CLICK ];
			}
			var interaction:Interaction = InteractionCreator.addToEntity( entity, interactions, MovieClip( EntityUtils.getDisplayObject( entity )).hit );		
			interaction.click.add( batReached );
			ToolTipCreator.addToEntity( entity );
		
			_hitContainer.swapChildren( Display( entity.get( Display )).displayObject, super._hitContainer[ "batEmpty" ]);
			
			var spatial:Spatial = super.player.get( Spatial );
			var spring:Spring = new Spring( spatial, .6, .09 );
			var wave:WaveMotion = new WaveMotion();
			var waveData:WaveMotionData = new WaveMotionData( "y", 8, .2 );
			wave.data.push( waveData );
			
			spring.offsetY = -200;
			spring.startPositioned = false;
			spring.rotateByVelocity = true;
			spring.rotateRatio = 4;
			spring.threshold = 8;
			
			var threshold:Threshold = new Threshold( "y", ">" );
			threshold.threshold = 1000;
			threshold.entered.add( stopBatFollow );
			entity.add( threshold ).add( spring ).add( new Id( "bat" )).add( new SpatialAddition()).add( wave );
			
			var audioRange:AudioRange = new AudioRange( 500, .01, 1 );
			entity.add( audioRange );
			
			_audioGroup.addAudioToEntity( entity );
			var audio:Audio = entity.get( Audio );
			audio.playCurrentAction( RANDOM );
		}
		
		private function batReached( bat:Entity ):void
		{
			var dialog:Dialog = player.get( Dialog );
			dialog.sayById( "examine_bat" );
		}	
		
		private function stopBatFollow():void
		{
			super.removeEntity( super.getEntityById( "bat" ));
		}
		
		private function changeScene():void
		{
			super.shellApi.loadScene( HadesPit2, 494, -200 );
		}
		
		private function unlockInput( dialogData:DialogData = null ):void
		{
			SceneUtil.lockInput( this, false, false );
		}
		
		private var _flameCreator:FlameCreator;
		private static const RANDOM:String	=		"random";
	}
}
