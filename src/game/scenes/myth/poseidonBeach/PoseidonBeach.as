package game.scenes.myth.poseidonBeach
{
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;
	import engine.group.TransportGroup;
	import engine.util.Command;
	
	import game.components.entity.Dialog;
	import game.components.timeline.Timeline;
	import game.creators.entity.BitmapTimelineCreator;
	import game.creators.entity.EmitterCreator;
	import game.creators.scene.HitCreator;
	import game.data.scene.hit.HitType;
	import game.data.scene.hit.WaterHitData;
	import game.scenes.myth.poseidonBeach.components.FlagComponent;
	import game.scenes.myth.poseidonBeach.popups.Hangman;
	import game.scenes.myth.poseidonBeach.systems.FlagSystem;
	import game.scenes.myth.shared.Fountain;
	import game.scenes.myth.shared.MythScene;
	import game.systems.ParticleSystem;
	import game.systems.SystemPriorities;
	import game.systems.hit.WaterHitSystem;
	import game.util.BitmapUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.PerformanceUtils;
	import game.util.SceneUtil;
	
	import org.flintparticles.common.displayObjects.Blob;
	
	public class PoseidonBeach extends MythScene
	{
		public function PoseidonBeach()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/myth/poseidonBeach/";
			
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
			
			super.shellApi.eventTriggered.add(eventTriggers);
			addSystem( new FlagSystem(), SystemPriorities.update );
			
			setupFountains();
			setupFlag();
			
			if( super.shellApi.checkEvent( _events.TELEPORT ))
			{
				if(PerformanceUtils.qualityLevel >= PerformanceUtils.QUALITY_MEDIUM)
				{
					var transportGroup:TransportGroup = super.addChildGroup( new TransportGroup()) as TransportGroup;
					transportGroup.transportIn( player );
				}
				else
				{
					this.shellApi.removeEvent(_events.TELEPORT);
					this.shellApi.triggerEvent(_events.TELEPORT_FINISHED);
				}
			}
		}
		
		// process incoming events
		private function eventTriggers( event:String, makeCurrent:Boolean = true, init:Boolean = false, removeEvent:String = null ):void
		{
			if( event == _events.APHRODITE_TEST )
			{
				SceneUtil.delay(this,0.6,showPopup);
			}
			else if( event=="lookGirl"){
				SceneUtil.lockInput( this, true );
				SceneUtil.setCameraTarget(this, getEntityById("char2"));
				Dialog(getEntityById("char2").get(Dialog)).complete.add(unlock);
			}
		}
		
		private function unlock(...p):void
		{
			SceneUtil.lockInput( this, false );
			SceneUtil.setCameraTarget(this, player);
		}
		
		/*******************************
		 * 		    FOUNTAINS
		 * *****************************/
		private function setupFountains():void
		{
			var entity:Entity;
			var audio:Audio;
			var audioRange:AudioRange;
		
			var spawnNumber:int = 35;
			var bitmapData:BitmapData = BitmapUtils.createBitmapData(new Blob( 8 ));
			
			audioRange = new AudioRange( 600, .01, 1 );
			
			var fountain:Fountain = new Fountain();
			
			if( PerformanceUtils.qualityLevel <= PerformanceUtils.QUALITY_MEDIUM )
			{
				spawnNumber = 10;
			}
			fountain.init( bitmapData, spawnNumber, -180, 155, 420 );
			entity = EntityUtils.createSpatialEntity( this, _hitContainer[ "fountain" ]);
			EmitterCreator.create( this, _hitContainer[ "fountain" ], fountain, 0, 0, entity );
			entity.add( audioRange ).add( new Id( "fountain" ));
			_audioGroup.addAudioToEntity( entity );
			
			audio = entity.get( Audio );
			audio.playCurrentAction( RANDOM );
			
			addSystem(new ParticleSystem(), SystemPriorities.update);
			
			// WATER HIT
			var waterHit:WaterHitSystem = super.getSystem( WaterHitSystem ) as WaterHitSystem;
			if( !waterHit )
			{
				waterHit = new WaterHitSystem();
				addSystem( waterHit, SystemPriorities.moveComplete );
			}
			
			var water:Entity = EntityUtils.createSpatialEntity( this, _hitContainer[ "aqua" ]);
			water.add( new Id( "water" ));
			var waterHitData:WaterHitData = new WaterHitData();
			waterHitData.density = WATER_DENSITY;
			waterHitData.splashColor1 = 0x41B6E1;
			waterHitData.splashColor2 = 0x4DCBDE;
			
			
			var hitCreator:HitCreator = new HitCreator();
			hitCreator.makeHit( water, HitType.WATER, waterHitData );
			hitCreator.addHitSoundsToEntity( water, _audioGroup.audioData, shellApi );
		}
		
		/*******************************
		 * 		      FLAG
		 * *****************************/
		private function setupFlag():void
		{
			var number:int;
			var audio:Audio = new Audio();
			var audioRange:AudioRange = new AudioRange( 600, .01, 1 );
			var spatial:Spatial;
			var clip:DisplayObject;
			var flag:FlagComponent = new FlagComponent();
			var entity:Entity;
			
			if(PerformanceUtils.qualityLevel >= PerformanceUtils.QUALITY_MEDIUM){
				entity = EntityUtils.createSpatialEntity( this, _hitContainer[ "flag" ]);
				DisplayUtils.destroyDisplayObject(_hitContainer[ "lqFlag" ]);
				for( number = 0; number < 6; number ++ )
				{
					clip = Display( entity.get( Display )).displayObject.getChildByName( "pt" + number );
					spatial = new Spatial( clip.x, clip.y );
					
					flag.points.push( spatial );
					flag.startY.push( spatial.y );
					
					if( number == 1 || number == 3 || number == 4 ) 
					{
						flag.timers.push( 1.5 );
					}
					else 
					{
						flag.timers.push( 0 );
					}
				}
				entity.add( flag );
			}
			else{
				DisplayUtils.destroyDisplayObject(_hitContainer[ "flag" ]);
				entity = EntityUtils.createSpatialEntity( this, _hitContainer[ "lqFlag" ]);
				BitmapTimelineCreator.convertToBitmapTimeline(entity, _hitContainer[ "lqFlag" ],true,null,1.5);
				Timeline(entity.get(Timeline)).playing = true;
			}

			entity.add( new Id( "flag" )).add( audioRange );
			_audioGroup.addAudioToEntity( entity );
			
			audio = entity.get( Audio );
			audio.playCurrentAction( RANDOM );
		}
		
		/*******************************
		 * 		     HANGMAN
		 * *****************************/
		private function showPopup():void
		{
			var popup:Hangman = super.addChildGroup(new Hangman(super.overlayContainer)) as Hangman;
			popup.id = "hangman";
			
			popup.complete.add( Command.create( completeHangman, popup ));
			popup.fail.add( Command.create( failedHangman, popup ));
			popup.closeClicked.add( quitHangman );
		}
		private function completeHangman( popup:Hangman ):void
		{
			popup.close();
			SceneUtil.delay(this, 0.5, Command.create(super.shellApi.triggerEvent, _events.APHRODITE_TEST_PASSED, true ));
			//super.shellApi.triggerEvent( _events.APHRODITE_TEST_PASSED, true );
		}
		
		private function failedHangman( popup:Hangman ):void
		{
			popup.close();
			SceneUtil.delay(this, 0.5, Command.create(super.shellApi.triggerEvent, _events.APHRODITE_TEST_FAILED, false, false ));
			//super.shellApi.triggerEvent( _events.APHRODITE_TEST_FAILED, false, false );
		}
		
		private function quitHangman( ...args ):void
		{
			SceneUtil.lockInput( this, false );
		}
		
//		private var _audioGroup:AudioGroup;
		private const WATER_DENSITY:Number 	= 1;
//		private const WATER_VISCOSITY:Number = .9;
		
//		private static const FLAG:String = 			"myth_flag_01_loop.mp3";
		private const RANDOM:String				=	"random";
	}
}