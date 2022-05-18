package game.scenes.lands.shared.tileLib.generation.generators {

	import flash.utils.Dictionary;
	
	import game.scenes.lands.shared.tileLib.LandTile;
	import game.scenes.lands.shared.tileLib.TileMap;

	public class ClumpGenerator extends MapGenerator {

		protected var minClumps:int = 3;
		protected var maxClumps:int = 8;

		protected var minClumpSize:int = 40;
		protected var maxClumpSize:int = 200;

		public function ClumpGenerator( map:TileMap=null ) {

			super( map );

		} //

		/**
		 * Sets the range of the size of each clump generated.
		 * The clumps may still intersect each other to form larger clumps.
		 */
		public function setClumpSizeRange( min:int, max:int ):void {

			this.minClumpSize = min;
			this.maxClumpSize = max;

		} //

		override public function generate( allSets:Dictionary=null ):void {

			var count:int = this.minClumps + Math.floor( Math.random()*(this.maxClumps - this.minClumps) );
			var size:int;

			var fringe:Vector.<LandTile> = new Vector.<LandTile>();
			var tile:LandTile;

			while ( count-- > 0 ) {

				// pick random tile, mark it filled, and add neighbors to the fringe.
				tile = super.getRandomTile();

				// instead of tileMap.fillTile() and tileMap.pushNeighbors(), could do these both in the generator itself
				// to save some processing time.
				this.tileMap.fillTile( tile, LandTile.FILLED );
				this.tileMap.pushNeighbors( fringe, tile.row, tile.col );

				size = this.minClumpSize + Math.floor( Math.random()*(this.maxClumpSize - this.minClumpSize) );

				while ( size-- > 0 ) {

					tile = getRandomFringe( fringe );
					this.tileMap.fillTile( tile, LandTile.FILLED );
					this.tileMap.pushNeighbors( fringe, tile.row, tile.col );

				} //

				// clear the fringe.
				fringe.length = 0;

			} // while-loop.

		} // generate()

		protected function fillTile( tile:LandTile ):void {

			tile.type = LandTile.FILLED;

		} //

		/**
		 * Add any empty neighbors to the fringe.
		 */
		protected function addNeighborsToFringe( fringe:Vector.<LandTile>, tile:LandTile ):void {

			var r:int = tile.row;
			var c:int = tile.col;

			/**
			 * Actually be more efficient to do the test here since the function
			 * does bounds checks we don't actually need.
			 */
			this.tileMap.pushTileIfEmpty( fringe, r-1, c );
			this.tileMap.pushTileIfEmpty( fringe, r+1, c );
			this.tileMap.pushTileIfEmpty( fringe, r, c-1 );
			this.tileMap.pushTileIfEmpty( fringe, r, c+1 );

		} //

		protected function getRandomFringe( fringe:Vector.<LandTile> ):LandTile {

			var ind:int = Math.floor( Math.random()*fringe.length );
			var t:LandTile = fringe[ ind ];

			fringe[ind] = fringe[ fringe.length-1 ];
			fringe.pop();

			return t;

		} //

		public function setMinClumps( n:int ):void {

			this.minClumps = n;

		} //

		public function setMaxClumps( n:int ):void {

			this.maxClumps = n;

		} //

	} // End ClumpGenerator
	
} // End package