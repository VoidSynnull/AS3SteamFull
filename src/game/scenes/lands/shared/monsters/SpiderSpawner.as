package game.scenes.lands.shared.monsters {

	import ash.core.Entity;
	
	import engine.components.Spatial;
	
	import game.scenes.lands.shared.LandGroup;
	import game.scenes.lands.shared.classes.LandGameData;
	import game.scenes.lands.shared.tileLib.tileSets.TileSet;
	import game.scenes.lands.shared.monsters.components.Spider;

	public class SpiderSpawner extends SpawnerBase {

		private var webHitColor:uint;
		
		public function SpiderSpawner( gameData:LandGameData ) {

			super( gameData );

			var treeSet:TileSet = gameData.tileSets["trees"];
			webHitColor = treeSet.getTypeByCode( 0x800000 ).hitGroundColor;

		} //

		override public function canSpawn( x:Number, y:Number, gd:LandGameData ):Boolean {

			if ( !( gd.tileHits.getHitAt( x, y ) == this.webHitColor ) ) {
				return false;
			}

			return true;

		} //

		override public function spawn( g:LandGroup, spatial:Spatial ):Entity {

			var e:Entity = super.createSpawnEntity( g, spatial, "spider.swf" )
				.add( new Spider(), Spider );

			return e;

		} //

	} // class
	
} // package