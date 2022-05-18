package game.scenes.myth.poseidonTemple
{
	import flash.display.BitmapData;
	import flash.display.DisplayObjectContainer;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
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
	import game.scenes.myth.shared.Fountain;
	import game.scenes.myth.shared.MythScene;
	import game.util.BitmapUtils;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.PerformanceUtils;
	import game.util.SceneUtil;
	
	import org.flintparticles.common.displayObjects.Blob;
	
	public class PoseidonTemple extends MythScene
	{
		public function PoseidonTemple()
		{
			super();
		}
	
		
		// pre load setup
		override public function init( container:DisplayObjectContainer = null ):void
		{			
			super.groupPrefix = "scenes/myth/poseidonTemple/";
			super.init( container );
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
			addFountains();
			super.shellApi.eventTriggered.add( eventTriggers );
		}
		
		// process incoming events
		private function eventTriggers( event:String, save:Boolean = true, init:Boolean = false, removeEvent:String = null ):void
		{
			if( event == _events.POSEIDON_OFFERING )
			{
				moveToAltar();
			}
		}		

		private function setupAltarAndDoor():void
		{
			beachDoor = getEntityById( "doorBeach" );
			altar = getEntityById( "altarInteraction" );
			offering = EntityUtils.createSpatialEntity( this,_hitContainer[ "offering" ]);
			gate = EntityUtils.createSpatialEntity( this,_hitContainer[ "gate" ]);
			
			
			
			if( shellApi.checkEvent( _events.POSEIDON_TEMPLE_OPEN ))
			{
				removeEntity( altar );
				removeEntity( gate );
			}
			
			else
			{
				var sceneInteraction:SceneInteraction = beachDoor.get( SceneInteraction );
				var spatial:Spatial = offering.get( Spatial );
				var display:Display = offering.get( Display );
				
				sceneInteraction.reached.removeAll();
				sceneInteraction.reached.add( doorReached );		
				
				sceneInteraction = altar.get( SceneInteraction );
				sceneInteraction.reached.add( altarReached );		
				spatial.x += 100;
				display.visible = false;
			}
		}

		private function doorReached( char:Entity, door:Entity ):void
		{
			// lock controls
			SceneUtil.lockInput( this );
			
			if( shellApi.checkEvent( _events.POSEIDON_TEMPLE_OPEN ))
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
			var positionX:Number = Spatial( super.player.get( Spatial )).x;
			
			// if beyond the far left platform
			if( positionX < 95 )
			{
				path.push( new Point( 50, 850 ));
				path.push( new Point( 100, 700 ));
			}
			
			// if beyond the middle platform
			if( positionX < 1150 )
			{
				path.push( new Point( 1030, 850 ));
				path.push( new Point(1160, 700 ));
				path.push( new Point( 1858, 850 ));
			}
			
			// to get over the last platform
				
			if( positionX < 2300 )
			{
				path.push( new Point( 1940, 850 ));
				path.push( new Point( 2100, 700 ));
			}
			
			path.push( new Point( 2220, 810 ));
			
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
				shellApi.triggerEvent( _events.POSEIDON_TEMPLE_OPEN, true );
			}
		}
	
		private function placeOffering():void
		{
			// place/remove starfish
			shellApi.removeItem( "starfish" );
			Display( offering.get( Display )).visible = true;
			
			// fade out door
			var tween:Tween = new Tween();
			gate.add( tween );
			tween.to( gate.get( Display ), 2, { alpha : 0, ease : Quadratic.easeInOut, onComplete : unlockInput });
			
			//place starfish
			tween = new Tween();
			offering.add( tween );
			tween.to( offering.get( Spatial ), .5, { x : 2125.45 });
			super.removeEntity( altar );
			
			// enable door
			SceneInteraction( beachDoor.get( SceneInteraction )).reached.add( doorReached );
			shellApi.triggerEvent("poseidon_temple_open");
			
		}
		
		private function unlockInput( dialogData:DialogData=null ):void
		{
			SceneUtil.lockInput( this, false, false );
		}
		
		private function addFountains():void
		{
			var entity:Entity;
			var number:int;
			var audio:Audio;
			var audioRange:AudioRange;
			var fountain:Fountain;
//			var audioGroup:AudioGroup = super.getGroupById( AudioGroup.GROUP_ID ) as AudioGroup;
			var spawnNumber:int = 35;
			var bitmapData:BitmapData = BitmapUtils.createBitmapData(new Blob(8));
			
			for ( number = 1; number < 3; number++ ) 
			{
				audioRange = new AudioRange( 600, .01, 1 );
				
				fountain = new Fountain();
				if( PerformanceUtils.qualityLevel <= PerformanceUtils.QUALITY_MEDIUM )
				{
					spawnNumber = 15;
				}
				
				fountain.init( bitmapData,spawnNumber, -180, 155, 420 );
				entity = EntityUtils.createSpatialEntity( this, _hitContainer[ "fountain" + number ] );
				EmitterCreator.create( this, _hitContainer[ "fountain" + number ], fountain, 0, 0, entity );
				entity.add( audioRange ).add( new Id( "fountain" + number ));
				_audioGroup.addAudioToEntity( entity );
				
				audio = entity.get( Audio );
				audio.playCurrentAction( RANDOM );
			}
		}
		
		private const RANDOM:String				= 	"random";
		
		private var beachDoor:Entity;
		private var gate:Entity;
		private var altar:Entity;
		private var offering:Entity;
	}
}