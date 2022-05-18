package game.scenes.lands.shared.tileLib.templates {
	
	import game.scenes.lands.shared.tileLib.LandTile;
	import game.scenes.lands.shared.tileLib.TileMap;

	/**
	 * CURRENTLY UNUSED - tileMaps are used directly instead. they waste memory but can be rendered automatically
	 * with existng classes.
	 * 
	 * a template grid is a section of tileType ids arranged in
	 * rows,cols of a certain size.
	 * 
	 * it is used to store a single tileMap section of a tileTemplate.
	 * 
	 */
	public class TemplateGrid {

		private var _rows:int;
		private var _cols:int;

		private var grid:Vector.< Vector.<uint> >;

		public function TemplateGrid( rows:int, cols:int ) {

			this.init( rows, cols );

		} //

		public function copyTo( tmap:TileMap, startRow:int, startCol:int ):void {

			var tiles:Vector.< Vector.<LandTile> >  = tmap.getTiles();

			var maxRow:int = this._rows;
			if ( startRow + maxRow >= tiles.length ) {
				maxRow = tiles.length - startRow;
			}

			var maxCol:int = this._cols;
			if ( startCol + maxCol >= tmap.cols ) {
				maxCol = tmap.cols - startCol;
			}

			for( var r:int = maxRow-1; r >= 0; r-- ) {

				for( var c:int = maxCol-1; c >= 0; c-- ) {

					tiles[ startRow + r ][ startCol + c ].type = this.grid[r][c];

				} //

			} // for-loop.

		} //

		public function copyFrom( tmap:TileMap, startRow:int, startCol:int ):void {

			var tiles:Vector.< Vector.<LandTile> >  = tmap.getTiles();

			var maxRow:int = this._rows;
			if ( startRow + maxRow >= tiles.length ) {
				maxRow = tiles.length - startRow;
			}

			var maxCol:int = this._cols;
			if ( startCol + maxCol >= tmap.cols ) {
				maxCol = tmap.cols - startCol;
			}

			for( var r:int = maxRow-1; r >= 0; r-- ) {

				for( var c:int = maxCol-1; c >= 0; c-- ) {

					this.grid[r][c] = tiles[ startRow + r ][ startCol + c ].type;

				} //

			} // for-loop.

		} //

		public function init( rows:int, cols:int ):void {

			this._rows = rows;
			this._cols = cols;

			this.grid = new Vector.< Vector.<uint> >( this._rows );

			var curRow:Vector.<uint>;

			for( var r:int = this._rows-1; r >= 0; r-- ) {

				curRow = new Vector.<uint>( this._cols );

				for( var c:int = this._cols-1; c >= 0; c-- ) {

					curRow[ c ] = new LandTile( r, c );

				} //

				this.grid[ r ] = curRow;

			} // for-loop.
			
		} //

		public function getGrid():Vector.< Vector.<uint> > {
			return this.grid;
		}

		public function get rows():int {
			return this._rows;
		}

		public function get cols():int {
			return this._cols;
		}

	} // class

} // package