package game.scenes.lands.shared.tileLib.generation.generators {

	/**
	 * fills all tiles below a given level.
	 */

	import game.scenes.lands.shared.classes.LandGameData;
	import game.scenes.lands.shared.tileLib.LandTile;
	import game.scenes.lands.shared.tileLib.TileMap;
	
	public class FlatGenerator extends MapGenerator {

		public var height:int = 5;

		public var tileType:int = 4;

		public var mixedTiles:Boolean = true;

		public function FlatGenerator( tmap:TileMap ) {

			super( tmap );

		} //

		// to start with, just going to have a constant land level.
		override public function generate( gameData:LandGameData=null ):void {

			var tiles:Vector.< Vector.<LandTile> > = super.tileMap.getTiles();

			var minRow:int = super.tileMap.rows - height;
			if ( minRow < 0 ) {
				minRow = 0;
			}

			if ( this.tileMap.allowMixedTiles ) {

				for( var r:int = tiles.length-1; r >= minRow; r-- ) {

					for( var c:int = super.tileMap.cols-1; c >= 0; c-- ) {

						tiles[r][c].type |= this.tileType;

					} //

				} // for-loop.

			} else {

				for( r = tiles.length-1; r >= minRow; r-- ) {

					for( c = super.tileMap.cols-1; c >= 0; c-- ) {

						tiles[r][c].type = this.tileType;
						
					} //
					
				} // for-loop.

			} // end-if.

		} //

	} // class

} // package