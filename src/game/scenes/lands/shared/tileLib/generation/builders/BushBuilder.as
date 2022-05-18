package game.scenes.lands.shared.tileLib.generation.builders {

	
	import game.scenes.lands.shared.classes.LandGameData;
	import game.scenes.lands.shared.tileLib.TileMap;
	import game.scenes.lands.shared.tileLib.classes.RandomMap;
	import game.scenes.lands.shared.tileLib.generation.data.TreeData;
	import game.scenes.lands.shared.tileLib.generation.generators.MapGenerator;

	public class BushBuilder extends MapGenerator {

		private var leafTile:uint;

		private var minWidth:int = 4;
		private var maxWidth:int = 12;

		/**
		 * minimum bush height.
		 */
		private var minHeight:int = 2;
		/**
		 * maximum bush height.
		 */
		private var maxHeight:int = 8;

		private var randMap:RandomMap;
		private var treeMap:RandomMap;

		public function BushBuilder( tmap:TileMap ) {

			super( tmap );

		} //

		public function generateAt( row:int, col:int, type:TreeData, gameData:LandGameData ):void {

			this.leafTile = type.leafTile;

			this.randMap = gameData.worldRandoms.randMap;
			this.treeMap = gameData.worldRandoms.treeMap;

			// need to make sure the bush isnt generated underground?
			var terrainMap:TileMap = gameData.tileMaps[ "terrain" ];

			var width:Number = this.minWidth + ( this.maxWidth - this.minWidth )*this.randMap.getRandom();

			var maxCol:int = col + width/2;
			if ( maxCol >= this.tileMap.cols ) {
				maxCol = this.tileMap.cols - 1;
			}
			for( var c:int = Math.max( 0, col - width/2 ); c <= maxCol; c++ ) {

				// note that distance from bush center decreases max height of bush.
				var h:int = this.minHeight + ( (this.maxHeight-Math.abs(c-col)*0.75) - this.minHeight )*this.treeMap.getNumberAt( c, row+17 );

				for( h = Math.max( 0, row-h ); h <= row; h++ ) {

					this.tileMap.fillTypeAt( h, c, this.leafTile );

				} //

			} // for-loop.

		} //

	} // class

} // package