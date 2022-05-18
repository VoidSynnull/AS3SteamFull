package game.scenes.virusHunter.mouthShip
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Motion;
	import engine.systems.CameraZoomSystem;
	import engine.util.Command;
	
	import game.components.entity.Sleep;
	import game.components.timeline.Timeline;
	import game.components.hit.MovieClipHit;
	import game.components.hit.Hazard;
	import game.components.hit.Zone;
	import game.data.TimedEvent;
	import game.scenes.virusHunter.VirusHunterEvents;
	import game.scenes.virusHunter.mouthShip.systems.MouthTargetSystem;
	import game.scenes.virusHunter.shared.ShipGroup;
	import game.scenes.virusHunter.shared.ShipScene;
	import game.scenes.virusHunter.shared.components.DamageTarget;
	import game.scenes.virusHunter.shared.components.Virus;
	import game.scenes.virusHunter.shared.data.EnemyType;
	import game.systems.SystemPriorities;
	import game.systems.timeline.TimelineClipSystem;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	
	public class MouthShip extends ShipScene
	{
		public function MouthShip()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.minCameraScale = .8;
			super.groupPrefix = "scenes/virusHunter/mouthShip/";
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
			
			_events = super.events as VirusHunterEvents;
			
			_shipGroup = super.getGroupById("shipGroup") as ShipGroup;
			_shipGroup.createSceneWeaponTargets(super._hitContainer);
			var mouthSystem:MouthTargetSystem = new MouthTargetSystem( this, _events );
			
			super.addSystem( mouthSystem , SystemPriorities.checkCollisions );
			
			setupTooth();
			
			var cameraZoom:CameraZoomSystem = super.getSystem( CameraZoomSystem ) as CameraZoomSystem;
			cameraZoom.scaleTarget = .8;
		}
		
		/*********************************************************************************
		 * TOOTH SECONDARY OBJECTIVE
		 */
		private function setupTooth():void
		{
			var tooth:Entity = EntityUtils.createSpatialEntity( this, super._hitContainer[ "toothArt" ]);
			var damageTarget:DamageTarget = super.getEntityById( "toothTarget" ).get( DamageTarget );
			
			var hazard:Hazard;
			var mCHit:MovieClipHit;
			
			tooth.add( new Id( "toothArt" ));
			
			if( super.shellApi.checkEvent( _events.TOOTH_REMOVED ))
			{
				super.removeEntity( super.getEntityById( "toothHazard" ));
				super.removeEntity( super.getEntityById( "toothArt" ));
				super.removeEntity( super.getEntityById( "tooth" ));
				super.removeEntity( super.getEntityById( "toothTarget" ));
			}
				
			else
			{
				alertSecondary();
				setupChips();
				TimelineUtils.convertClip( MovieClip( EntityUtils.getDisplayObject( tooth )), this, tooth );
				var timeline:Timeline = tooth.get( Timeline );
				tooth = super.getEntityById( "toothHazard" );
				
				if( super.shellApi.checkEvent( _events.TOOTH_CHIPPED_ + "4" ))
				{
					timeline.gotoAndStop( 4 );
					damageTarget.damage = 8.2;
				}
				else if( super.shellApi.checkEvent( _events.TOOTH_CHIPPED_ + "3" ))
				{
					timeline.gotoAndStop( 3 );
					damageTarget.damage = 6.2;
				}
				else if( super.shellApi.checkEvent( _events.TOOTH_CHIPPED_ + "2" ))
				{
					timeline.gotoAndStop( 2 );
					damageTarget.damage = 4.2;
				}
				else if( super.shellApi.checkEvent( _events.TOOTH_CHIPPED_ + "1" ))
				{
					timeline.gotoAndStop( 1 );
					damageTarget.damage = 2.2;
				}
				else
				{
					timeline.gotoAndStop( 0 );
				}
				
				hazard = tooth.get( Hazard );
				hazard.velocity = new Point(4, 4);
				hazard.damage = 0.5;
				hazard.coolDown = .75;
				
				mCHit = new MovieClipHit( EnemyType.ENEMY_HIT, "ship" );
				mCHit.shapeHit = true;
				mCHit.hitDisplay = MovieClip( EntityUtils.getDisplayObject( tooth ));
				tooth.add( mCHit );
			}
			
			for( var number:int = 1; number < 3; number ++ )
			{
				tooth = super.getEntityById( "tooth" + number + "Hazard" );
				hazard = tooth.get( Hazard );
				hazard.velocity = new Point(4, 4);
				hazard.damage = 0.5;
				hazard.coolDown = .75;
				
				mCHit = new MovieClipHit( EnemyType.ENEMY_HIT, "ship" );
				mCHit.shapeHit = true;
				mCHit.hitDisplay = MovieClip( EntityUtils.getDisplayObject( tooth ));
				tooth.add( mCHit );
			}
			
			var zone:Entity = super.getEntityById( "zone" );
			Zone( zone.get( Zone )).entered.addOnce( createVirusSpawn );
		}
		
		private function createVirusSpawn( zoneId:String, entityId:String ):void
		{
			super.removeEntity( super.getEntityById( "zone" ), true );
			var virus:Virus = new Virus();
			_shipGroup.createOffscreenSpawn(EnemyType.VIRUS, 5, .5, virus.seekVelocity, virus.seekVelocity + 25);
		}
		
		private function alertSecondary():void
		{
			SceneUtil.addTimedEvent( this, new TimedEvent( 2, 1, Command.create( super.playMessage, "mouth_secondary", false, "mouth_secondary", "drLang" )));
		}
		
		private function setupChips():void
		{
			for( var i:int = 0; i < numChips * 4; i ++ )
			{
				super.loadFile( "chip.swf", onChipLoad, i );
			}
		}
		
		private function onChipLoad( clip:MovieClip, i:int ):void
		{
			var chip:Entity = EntityUtils.createMovingEntity( this, clip, super._hitContainer );
			chip.add( new Id( "chip" + i ));
			chip.add( new Sleep( false, true ));
			
			TimelineUtils.convertClip( clip, null, chip );
			Timeline( chip.get( Timeline )).gotoAndStop( 0 );
			
			chip.get( Display ).alpha = 0;
			
			var motion:Motion = chip.get( Motion );
			motion.acceleration.y = 600;
			motion.pause = true;
		}
		
		public var currentChip:int = 1;
		public var numChips:int = 4;
		private var _events:VirusHunterEvents;
		private var _shipGroup:ShipGroup;
	}
}

