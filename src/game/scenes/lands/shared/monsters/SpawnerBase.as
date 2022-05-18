package game.scenes.lands.shared.monsters {

	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.scene.template.PlatformerGameScene;
	import game.scenes.lands.shared.LandGroup;
	import game.scenes.lands.shared.classes.LandGameData;

	/**
	 * base class for monster spawners.
	 */
	public class SpawnerBase {

		public function SpawnerBase( gameData:LandGameData ) {
		} //

		public function trySpawn( g:LandGroup, x:int, y:int ):Entity {

			return null;

		} //

		public function isActive( gameData:LandGameData ):Boolean {
			return true;
		}

		public function canSpawn( x:Number, y:Number, gd:LandGameData ):Boolean {

			return false;

		} //

		public function spawn( g:LandGroup, spatial:Spatial ):Entity {
			return null;
		} //

		public function createSpawnEntity( g:LandGroup, spatial:Spatial, spawnFile:String ):Entity {
			
			var e:Entity = new Entity()
				.add( spatial, Spatial );
			
			g.shellApi.loadFile( g.sharedAssetURL + spawnFile, this.monsterClipLoaded, g, e );
			
			return e;
			
		}

		private function monsterClipLoaded( clip:MovieClip, group:LandGroup, spawnEntity:Entity ):void {

			( group.parent as PlatformerGameScene ).hitContainer.addChild( clip );
			spawnEntity.add( new Display( clip ), Display );

			group.addEntity( spawnEntity );

		} //

	} // class
	
} // package