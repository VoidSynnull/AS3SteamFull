package game.scenes.lands.shared.tileLib.generation.generators {

	/**
	 * This generator will fill LandMap tiles so they make the ground for a scene.
	 * For test, it will only be a flat line.
	 */

	import game.scenes.lands.shared.classes.LandGameData;
	import game.scenes.lands.shared.tileLib.LandTile;
	import game.scenes.lands.shared.tileLib.TileMap;
	
	public class GroundGenerator extends MapGenerator {

		public var minHeight:int = 3;
		public var maxHeight:int = 14;

		public function GroundGenerator( map:TileMap=null ) {

			super( map );

		} //

		// to start with, just going to have a constant land level.
		override public function generate( gameData:LandGameData=null ):void {

			var tiles:Vector.< Vector.<LandTile> > = super.tileMap.getTiles();

			var minRow:int = super.tileMap.rows - minHeight;
			if ( minRow < 0 ) {
				minRow = 0;
			}

			for( var r:int = tiles.length-1; r >= minRow; r-- ) {

				for( var c:int = super.tileMap.cols-1; c >= 0; c-- ) {

					tiles[r][c].type = LandTile.FILLED;

				} //

			} // for-loop.

			// now set the border variables for the very top tiles.
			for( c = super.tileMap.cols-1; c >= 0; c-- ) {

				tiles[minRow][c].borders = LandTile.TOP;

			} //

		} //

	} // class

} // package