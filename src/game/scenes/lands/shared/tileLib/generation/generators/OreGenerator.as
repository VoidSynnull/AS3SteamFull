package game.scenes.lands.shared.tileLib.generation.generators {

	/**
	 * Generates ore all over the map - must be underground.
	 */

	
	import game.scenes.lands.shared.classes.LandGameData;
	import game.scenes.lands.shared.tileLib.TileMap;
	import game.scenes.lands.shared.tileLib.classes.RandomMap;
	import game.scenes.lands.shared.tileLib.tileSets.TileSet;

	public class OreGenerator extends MapGenerator {

		/**
		 * the row to use in the master perlin random map to generate the ore.
		 */
		private const generateRow:int = 17;

		// whatever. this should be poptanium.
		public var oreType:uint = 4;

		public var oreThreshold:uint = 0xD00000;

		public function OreGenerator( tmap:TileMap ) {

			super( tmap );

		} // OreGenerator()

		override public function generate( gameData:LandGameData=null ):void {

			var oreMap:RandomMap = gameData.worldRandoms.terrainMap;

			for( var r:int = this.tileMap.rows-1; r >= 0; r-- ) {

				for( var c:int = this.tileMap.cols-1; c >= 0; c-- ) {

					if ( oreMap.getIntAt( c, r ) > this.oreThreshold && this.tileMap.getTileType( r, c ) != 0 ) {

						this.tileMap.fillTypeAt( r, c, this.oreType );

					} //

				} // for

			} // for

		} // generate()

	} // class

} // package