package game.scenes.myth.poseidonThrone
{
	import flash.display.BitmapData;
	import flash.display.DisplayObjectContainer;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Id;
	
	import game.creators.entity.EmitterCreator;
	import game.creators.scene.HitCreator;
	import game.data.game.GameEvent;
	import game.data.scene.hit.HitType;
	import game.data.scene.hit.WaterHitData;
	import game.scenes.myth.poseidonThrone.systems.PoseidonBeardSystem;
	import game.scenes.myth.shared.Fountain;
	import game.scenes.myth.shared.MythScene;
	import game.systems.ParticleSystem;
	import game.systems.SystemPriorities;
	import game.systems.hit.WaterHitSystem;
	import game.util.BitmapUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.PerformanceUtils;
	import game.util.SkinUtils;
	
	import org.flintparticles.common.displayObjects.Blob;
	
	public class PoseidonThrone extends MythScene
	{
		private const WATER_DENSITY:Number 	= 1;
//		private const WATER_VISCOSITY:Number = .9;
//		private var _audioGroup:AudioGroup;
		private const RANDOM:String					= "random";
		
		public function PoseidonThrone()
		{
			super();
		}
		
		// pre load setup
		override public function init( container:DisplayObjectContainer = null ):void
		{			
			super.groupPrefix = "scenes/myth/poseidonThrone/";
			
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
			
//			_audioGroup = super.getGroupById( AudioGroup.GROUP_ID ) as AudioGroup;
			shellApi.eventTriggered.add( eventTriggers );
			
			addFountains();
			
			if( super.shellApi.checkEvent( GameEvent.GOT_ITEM + _events.POSEIDON_TRIDENT ))
			{
				SkinUtils.setSkinPart( getEntityById( "poseidon" ), SkinUtils.ITEM, "empty" );
			}
			
			addSystem( new PoseidonBeardSystem(), SystemPriorities.update );
			addSystem(new ParticleSystem(), SystemPriorities.update);
			
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
		
		private function eventTriggers( event:String, save:Boolean = true, init:Boolean = false, removeEvent:String = null ):void
		{
			if( event == GameEvent.GOT_ITEM + _events.POSEIDON_TRIDENT )
			{
				SkinUtils.setSkinPart( getEntityById( "poseidon" ), SkinUtils.ITEM, "empty" );
			}
		}
		
		private function addFountains():void
		{
			var entity:Entity;
			var number:int;
			var audio:Audio;
			var fountain:Fountain;
			var audioRange:AudioRange;
			var spawnNumber:int = 35;
			
			var bitmapData:BitmapData = BitmapUtils.createBitmapData(new Blob( 8 ));
			
			for ( number = 1; number < 4; number++ ) 
			{
				audioRange = new AudioRange( 600, .01, 1 );
				
				fountain = new Fountain();
				if( PerformanceUtils.qualityLevel <= PerformanceUtils.QUALITY_MEDIUM )
				{
					spawnNumber = 15;
				}
				fountain.init( bitmapData, spawnNumber, 90, 180, 240 );
				entity = EntityUtils.createSpatialEntity( this, _hitContainer[ "fountain" + number ] );
				EmitterCreator.create( this, _hitContainer[ "fountain" + number ], fountain, -2, 0, entity );
				entity.add( audioRange ).add( new Id( "fountain" + number ));
				_audioGroup.addAudioToEntity( entity );
				
				audio = entity.get( Audio );
				audio.playCurrentAction( RANDOM );
			}
		}
	}
}