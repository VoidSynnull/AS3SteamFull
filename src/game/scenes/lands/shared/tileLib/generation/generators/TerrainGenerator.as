package game.scenes.lands.shared.tileLib.generation.generators {

	import flash.utils.Dictionary;
	
	import game.scenes.lands.shared.classes.LandGameData;
	import game.scenes.lands.shared.tileLib.LandTile;
	import game.scenes.lands.shared.tileLib.TileMap;

	public class TerrainGenerator extends MapGenerator {

		//public var minGrassHeight:int = 0;
		//public var maxGrassHeight:int = 50;

		public var minDirtHeight:int = 10;
		public var maxDirtHeight:int = 38;

		public var minStoneHeight:int = 0;
		public var maxStoneHeight:int = 44;

		//private var perlinWidth:int = 64;
		//private var perlinHeight:int = 32;

		public var grassType:int = 4;
		public var dirtType:int = 2;
		public var stoneType:int = 1;

		public function TerrainGenerator( tmap:TileMap ) {

			super( tmap );

		}

		override public function generate( gameData:LandGameData=null ):void {

			this.randomMap = gameData.worldRandoms.terrainMap;

			this.fillTo( this.dirtType, this.minDirtHeight, this.maxDirtHeight, 24 );
			this.fillTo( this.stoneType, this.minStoneHeight, this.maxStoneHeight, 30  );

			this.addTopGrass();

		} //

		/**
		 * Go through all the land and if anything has air above it, make it a layer of grass.
		 */
		private function addTopGrass():void {

			var tiles:Vector.< Vector.<LandTile> > = this.tileMap.getTiles();
			var prevRow:Vector.<LandTile> = tiles[0];			// first row doesn't matter.
			var curRow:Vector.<LandTile>;

			var rows:int = this.tileMap.rows;
			var cols:int = this.tileMap.cols;

			for( var r:int = 1; r < rows; r++ ) {
				
				curRow = tiles[r];
				
				for( var c:int = cols-1; c >= 0; c-- ) {

					// jordan says: only place grass over dirt.
					if ( curRow[c].type == dirtType && prevRow[c].type == LandTile.EMPTY ) {
						curRow[c].type = grassType;
					} //

				} //

				prevRow = curRow;

			} // for-loop.

		} // addTopGrass()

		/**
		 * fill a land type from 0 to a random height between min and max.
		 */
		private function fillTo( curType:int, minHeight:int, maxHeight:int, perlinY ):void {
			
			var tiles:Vector.< Vector.<LandTile> > = this.tileMap.getTiles();
			
			var rows:int = tiles.length-1;
			
			var h:int;
			
			for( var c:int = this.tileMap.cols-1; c >= 0; c-- ) {
				
				// here we subtract the height from 'rows' because the rows go from the top of the screen down.
				// so the largest row is actually the lowest land.
				h = minHeight + (maxHeight - minHeight)*( this.randomMap.getNumberAt( c, perlinY ) );
				h = rows - h;			// height actually counts from largest row down.
				
				//trace( "REd CHANNEL: " + (this.randomMap.getIntAt( c, perlinY ) >> 16) );
				
				while ( h <= rows ) {
					tiles[h++][c].type = curType;
				} //
				
			} // for-loop.
			
		} //

		/**
		 * fill the bottom tiles of the map with curType until they hit a non-empty tile above.
		 */
		private function fillBottom( curType:int ):void {
			
			var tiles:Vector.< Vector.<LandTile> > = this.tileMap.getTiles();
			var rows:int = tiles.length-1;
			var tile:LandTile;
			
			for( var c:int = this.tileMap.cols-1; c >= 0; c-- ) {
				
				for( var r:int = rows; r >= 0; r-- ) {
					
					tile = tiles[r][c];
					if ( tile.type == LandTile.EMPTY ) {
						tile.type = curType;
					} else {
						break;		// this column has been filled.
					} //
					
				} // for-loop.
				
			} // for-loop.
			
		} //

		/**
		 * start at a height between intermediate values and fill upwards (row going towards 0) until you hit something.
		 */
		/*private function fillLandUp( curType:uint, minHeight:int, maxHeight:int, perlinY:int ):void {
		
		var tiles:Vector.< Vector.<LandTile> > = this.tileMap.getTiles();
		
		var rows:int = tiles.length-1;
		var h:int;
		var tile:LandTile;
		
		for( var c:int = this.tileMap.cols-1; c >= 0; c-- ) {
		
		h = minHeight + (maxHeight - minHeight)*this.randomMap.getNumberAt( c, perlinY );
		h = rows - h;
		
		while ( h >= 0 ) {
		
		tile = tiles[h][c];
		if ( tile.type != LandTile.EMPTY ) {
		break;
		}
		tile.type = curType;
		h--;
		
		} // end-while loop.
		
		} // for-loop.
		
		} //*/

		/**
		 * 
		 * this function, not currently used, fills land between the given minHeight and maxHeight.
		 * 
		 * filling the land is actually a sort of unnatural operation because the land vectors are arranged in rows,cols
		 * whereas tile generation cycles over cols, rows.
		 * 
		 * perlinY0 and perlinY1 are used for picking rows in the perlin bitmap for random number generation.
		 */
		/*private function fillLandRange( curType:uint, minHeight:int, maxHeight:int, perlinY:int ):void {

			var tiles:Vector.< Vector.<LandTile> > = this.tileMap.getTiles();

			var rows:int = tiles.length-1;

			var h:int;
			var h1:int;
			var h2:int;

			for( var c:int = this.tileMap.cols-1; c >= 0; c-- ) {

				// here we subtract the height from 'rows' because the rows go from the top of the screen down.
				// so the largest row is actually the lowest land.
				h1 = minHeight + (maxHeight - minHeight)*( this.randomMap.getNumberAt( c, perlinY ) );
			//	trace( "PERLIN VALUE: " + randomMap.getIntAt( c, perlinY0 ) );
				h1 = rows - h1;

				h2 = minHeight + (maxHeight - minHeight)*( this.randomMap.getNumberAt( c, perlinY + 4 ) );
				h2 = rows - h2;

				if ( h1 > h2 ) {
					h = h2;
					h2 = h1;
				} else {				// height2 is larger than height1
					h = h1;
				}

				//trace( "start: " + h  + " ---- " + " end: " + h2 );

				while ( h <= h2 ) {

					tiles[h++][c].type = curType;

				} // end-while loop.

			} // for-loop.

		} //*/

		/*public function setMap( map:TileMap ):void {

			this.tileMap = map;

		} //*/

	} // class

} // package