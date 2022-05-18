package game.scenes.lands.shared.monsters {

	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.scene.template.PlatformerGameScene;
	import game.scenes.lands.shared.LandGroup;
	import game.scenes.lands.shared.classes.LandGameData;
	import game.scenes.lands.shared.components.LightningTarget;
	import game.scenes.lands.shared.components.SimpleTarget;
	import game.scenes.lands.shared.monsters.components.PixieMonster;
	import game.scenes.lands.shared.monsters.systems.PixieMonsterSystem;
	import game.scenes.lands.shared.systems.SimpleTargetSystem;
	import game.systems.SystemPriorities;

	public class PixieSpawner extends SpawnerBase {

		public function PixieSpawner( gameData:LandGameData ) {

			super( gameData );

		}

		override public function isActive( gameData:LandGameData ):Boolean {

			// come out at night
			if ( gameData.worldMgr.publicMode || !gameData.clock.isTwilight()
				|| Math.random() > 0.1 || gameData.inventory.getResourceCount("poptanium") < 250  ) {
				return false;
			}

			return true;

		} //

		override public function canSpawn( x:Number, y:Number, gameData:LandGameData ):Boolean {

			// only spawn on an 'outside' tile. it needs to be connected to the outside.. in this case the top of the screen, say.
			// left-right screen connections are less important because the user could have a house extending in those directions.
			if ( ( Math.random() < 0.005 ) &&
				( gameData.tileHits.isEmpty( x, y ) ) &&
				(y < gameData.tileHits.findTopY( x )) ) {
				return true;
			} //

			return false;

		} //

		override public function spawn( g:LandGroup, spatial:Spatial ):Entity {

			var e:Entity = new Entity()
				.add( spatial, Spatial )
				//.add( new Motion(), Motion )
				.add( new SimpleTarget( spatial.x, spatial.y ), SimpleTarget )
				.add( new PixieMonster(), PixieMonster );

			g.shellApi.loadFile( g.sharedAssetURL + "pixie.swf", this.onPixieLoaded, g, e );

			return e;

		} //

		private function onPixieLoaded( clip:MovieClip, group:LandGroup, pixieEntity:Entity ):void {

			if ( !group.getSystem( PixieMonsterSystem ) ) {
				group.addSystem( new PixieMonsterSystem(), SystemPriorities.update );
			}

			if ( !group.getSystem( SimpleTargetSystem ) ) {
				group.addSystem( new SimpleTargetSystem(), SystemPriorities.update );
			}

			( group.parent as PlatformerGameScene ).hitContainer.addChild( clip );
			pixieEntity.add( new Display( clip ), Display )
				.add( new LightningTarget( clip, 0.05 ), LightningTarget );

			group.addEntity( pixieEntity );

		} //

	} // class
	
} // package