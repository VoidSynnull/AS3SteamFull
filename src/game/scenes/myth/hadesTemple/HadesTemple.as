package game.scenes.myth.hadesTemple
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;
	import engine.components.Tween;
	
	import fl.motion.easing.Quadratic;
	
	import game.components.entity.Dialog;
	import game.components.hit.Door;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.Timeline;
	import game.creators.entity.EmitterCreator;
	import game.data.animation.entity.character.PlacePitcher;
	import game.data.scene.characterDialog.DialogData;
	import game.particles.FlameCreator;
	import game.scenes.myth.shared.MythScene;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.Fade;
	import org.flintparticles.common.actions.ScaleImage;
	import org.flintparticles.common.counters.Random;
	import org.flintparticles.common.displayObjects.Dot;
	import org.flintparticles.common.initializers.AlphaInit;
	import org.flintparticles.common.initializers.ColorInit;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.RandomDrift;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.LineZone;
	import org.flintparticles.twoD.zones.RectangleZone;
	
	public class HadesTemple extends MythScene
	{
		public function HadesTemple()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/myth/hadesTemple/";
			
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
						
			setupAltarAndDoor();
			super.shellApi.eventTriggered.add( eventTriggers );
			setupTorches();
		}
		
		override public function destroy():void
		{
			_flameCreator.destroy();
			super.destroy();
		}
		
		// process incoming events
		private function eventTriggers( event:String, save:Boolean = true, init:Boolean = false, removeEvent:String = null ):void
		{
			if( event == _events.HADES_OFFERING )
			{
				moveToAltar();
			}
		}		
		
		private function setupAltarAndDoor():void
		{
			pitDoor = getEntityById( "doorPit" );
			altar = getEntityById( "altarInteraction" );
			offering = EntityUtils.createSpatialEntity( this,_hitContainer[ "offering" ]);
			gate = EntityUtils.createSpatialEntity( this,_hitContainer[ "gate" ]);	
			
			if( shellApi.checkEvent( _events.HADES_TEMPLE_OPEN ))
			{
				removeEntity( altar );
				removeEntity( gate );
			}
				
			else
			{
				SceneInteraction( pitDoor.get( SceneInteraction )).reached.removeAll();
				SceneInteraction( pitDoor.get( SceneInteraction )).reached.add( doorReached );				
				SceneInteraction( altar.get( SceneInteraction )).reached.add( altarReached );		
				Spatial( offering.get( Spatial )).x += 100;
				Display( offering.get( Display )).visible = false;
				gate.add( new Id( "gate" ));
				
//				var audioGroup:AudioGroup = super.getGroupById("audioGroup") as AudioGroup;
				// this will add any audio matching this entity's id of 'npc' to its Audio component.
				_audioGroup.addAudioToEntity( gate );
			}
		}
		
		private function doorReached( char:Entity, door:Entity ):void
		{
			// lock controls
			SceneUtil.lockInput( this );
			
			if( shellApi.checkEvent( _events.HADES_TEMPLE_OPEN ))
			{
				// open
				Door( door.get( Door )).open = true;
			}
			else
			{
				// not open
				Dialog( char.get( Dialog )).sayById( "doorLocked" );
				Dialog( char.get( Dialog )).complete.add( unlockInput );
			}
		}
		
		private function altarReached( char:Entity, door:Entity ):void
		{
			SceneUtil.lockInput( this );
			Dialog( char.get( Dialog )).sayById( "examineAltar" );
			Dialog( char.get( Dialog )).complete.add( unlockInput );
		}	
		
		private function moveToAltar():void
		{		
			SceneUtil.lockInput( this );		
			
			var path:Vector.<Point> = new Vector.<Point>();	
	
			path.push( new Point( 2025, 830 ));
			
			CharUtils.followPath( shellApi.player, path, positionForOffering, false );
		}
		
		private function positionForOffering( entity:Entity ):void
		{
			CharUtils.setDirection( entity, false );
			CharUtils.setAnim( entity, PlacePitcher );
			
			var timeline:Timeline = CharUtils.getTimeline( super.player );
			timeline.labelReached.add( onPlayerAnimeLabel );
		}
		
		public function onPlayerAnimeLabel( label:String ):void
		{
			if( label == "trigger" )
			{
				placeOffering();
				shellApi.triggerEvent( _events.HADES_TEMPLE_OPEN, true );
			}
		}
		
		private function placeOffering():void
		{
			// place/remove starfish
			shellApi.removeItem( "pomegranates" );
			Display( offering.get( Display )).visible = true;
			
			// fade out door
			var tween:Tween = new Tween();
			gate.add( tween );
			tween.to( gate.get( Display ), 2, { alpha : 0, ease : Quadratic.easeInOut, onComplete : unlockInput });
			
			//place starfish
			tween = new Tween();
			offering.add( tween );
			tween.to( offering.get( Spatial ), .5, { x : 1935.5 });
			super.removeEntity( altar );
			
			// enable door
			SceneInteraction( pitDoor.get( SceneInteraction )).reached.add( doorReached );	
			
			var emitter2:Emitter2D = new Emitter2D();
			
			emitter2.counter = new Random( 25, 40 );
			emitter2.addInitializer( new ImageClass( Dot, [ 8 ], true ));
			emitter2.addInitializer( new ColorInit( 0x6FC970, 0x418A28 ));	// initialize from a color range
			emitter2.addInitializer( new AlphaInit( .8, 1 ));				// initialize from a alpha range
			emitter2.addInitializer( new Position( new RectangleZone( -80, -25, 80, 115 )));
			emitter2.addInitializer( new Velocity( new LineZone( new Point( 0, -120 ), new Point( 0, -80 ))));
			emitter2.addInitializer( new Lifetime( .5, 1.5 ));
			emitter2.addAction( new Age( Quadratic.easeIn ));
			emitter2.addAction( new Move());
			emitter2.addAction( new Accelerate( 0, -80 ));
			emitter2.addAction( new RandomDrift( 15, 15 ));				// add a random drift
			emitter2.addAction( new Fade( 1, 0 ));								// cause alpha to decrease with age
			emitter2.addAction( new ScaleImage( 1, .4 ));					// cause scale to decrease with age
			
			EmitterCreator.create( this, EntityUtils.getDisplayObject( gate ), emitter2, 0, -20 );
		}
		
		private function unlockInput( dialogData:DialogData = null ):void
		{
			SceneUtil.lockInput( this, false, false );
		}
		
		
		private function setupTorches():void
		{
			_flameCreator = new FlameCreator();
			_flameCreator.setup( this, super._hitContainer[ "flame" + 1 ], null, onFlameLoaded );
		}
		
		private function onFlameLoaded():void
		{
			var clip:MovieClip;
			var i:uint = 1;
			for( i = 1; i < 11; i ++ )
			{
				clip = super._hitContainer[ "flame" + i ];
				_flameCreator.createFlame( this, clip, true );
			}
		}
		
		private var pitDoor:Entity;
		private var gate:Entity;
		private var altar:Entity;
		private var offering:Entity;
		private var _flameCreator:FlameCreator;
	}
}