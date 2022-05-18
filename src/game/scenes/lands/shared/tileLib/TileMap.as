package game.scenes.lands.shared.tileLib {

	import flash.geom.Point;
	import flash.utils.Dictionary;
	
	import game.scenes.lands.shared.tileLib.classes.TileLayer;
	import game.scenes.lands.shared.tileLib.generation.generators.MapGenerator;
	import game.scenes.lands.shared.tileLib.renderers.MapRenderer;
	import game.scenes.lands.shared.tileLib.tileSets.TileSet;
	import game.scenes.lands.shared.tileLib.tileTypes.TileType;

	public class TileMap {

		protected var _rows:int;
		protected var _cols:int;

		protected var tiles:Vector.< Vector.<LandTile> >;

		/**
		 * tile set used in this map.
		 */
		public var tileSet:TileSet;

		public var layer:TileLayer;

		/**
		 * Internal name for the tileMap. used so other objects can refer to the map.
		 */
		public var name:String;

		/**
		 * order to draw this tile map within a tile layer. Lower drawOrders are drawn first
		 * with higher draw orders drawn over them.
		 */
		public var drawOrder:int = 0;

		/**
		 * if true, this tileMap draws hits to the hits bitmap - though individual tile types or renderers
		 * might ignore this option.
		 */
		public var drawHits:Boolean = true;

		/**
		 * When searching through the tiles of the tile map, it's usually important to know if you've already visited
		 * a particular tile in the current search.
		 * 
		 * Before a search begins, call beginSearch() to increment the cur_search counter. Then, whenever a tile is
		 * visited by the search, set its search_id to the cur_search. Any tile with search_id less then the cur_search
		 * has not been visited by that search yet.
		 */
		public var cur_search:uint = 0;

		/**
		 * if we limit tileSizes to powers of two, we can improve performance by using bitshift division and bit-masking modulus.
		 */
		public var tileSize:int = 64;
		//public var logSize:int;

		public var renderers:Vector.<MapRenderer>;
		public var generators:Vector.<MapGenerator>;

		public function TileMap( mapName:String=null ) {

			this.name = mapName;

		} //

		public function setTileSize( newSize:int ):void {

			this.tileSize = newSize;
			//this.logSize = Math.LOG2E*Math.log( newSize );

		} //

		public function init( rows:int, cols:int ):void {

			this._rows = rows;
			this._cols = cols;

			this.tiles = new Vector.< Vector.<LandTile> >( this._rows );
			
			var curRow:Vector.<LandTile>;
			var tile:LandTile;
			var jiggle:Number = this.tileSize/10;

			for( var i:int = this._rows-1; i >= 0; i-- ) {

				curRow = new Vector.<LandTile>( this._cols );

				for( var j:int = this._cols-1; j >= 0; j-- ) {

					curRow[ j ] = tile = new LandTile( i, j );
					tile.jiggle( jiggle );

				} //

				this.tiles[ i ] = curRow;

			} // for-loop.
			
		} //

		/**
		 * Preferred function for intializing tileMaps that use ClipTileTypes.
		 *
		 * in ClipTileType tile maps, computing jiggle factors is a waste of time
		 * at the init() stage.
		 */
		public function initNoJiggle( rows:int, cols:int ):void {
			
			this._rows = rows;
			this._cols = cols;
			
			this.tiles = new Vector.< Vector.<LandTile> >( this._rows );
			
			var curRow:Vector.<LandTile>;
			var tile:LandTile;

			for( var i:int = this._rows-1; i >= 0; i-- ) {

				curRow = new Vector.<LandTile>( this._cols );

				for( var j:int = this._cols-1; j >= 0; j-- ) {

					curRow[ j ] = tile = new LandTile( i, j );

				} //
				
				this.tiles[ i ] = curRow;
				
			} // for-loop.
			
		} //

		/**
		 * Simply increments the cur_search, so tiles with lower search_ids
		 * can be treated as unsearched.
		 */
		public function beginSearch():void {

			this.cur_search++;
			// might include a check here for overflow, but that shouldn't happen.

		} //

		/**
		 * adds the tile type to the tile, without erasing any other types.
		 */
		public function fillType( tile:LandTile, type:uint ):void {

			if ( this.tileSet.allowMixedTiles ) {
				tile.type |= type;
			} else {
				tile.type = type;
			}

		} //

		public function fillTypeAt( r:int, c:int, type:uint ):void {

			if  (this.tileSet.allowMixedTiles ) {
				this.tiles[r][c].type |= type;
			} else {
				this.tiles[r][c].type = type;
			}

		} //

		/**
		 * Fills a tile by setting tile.type to a non-empty tile-type.
		 * 
		 * the borders of the tile are set for any neighbors with a different tile type.
		 * The neighbor tiles themselves are also marked as having a border if their
		 * tile type is different.
		 */
		public function fillTile( tile:LandTile, type:uint ):void {

			tile.type = type;

		} //

		/**
		 * Clear one type from the given tile. The tile might now be empty,
		 * or it might still have other types.
		 */
		public function clearType( tile:LandTile, type:uint ):void {

			tile.type ^= type;

		} //

		public function clearTypeAt( r:int, c:int, type:uint ):void {

			this.tiles[r][c].type ^= type;

		} //

		/**
		 * does not check bounds.
		 */
		public function clearTileAt( r:int, c:int ):void {

			this.tiles[r][c].type = LandTile.EMPTY;

		} //

		/**
		 * Gets the type of the tile at row, col.
		 * 
		 * This function does not perform any bounds checking - you must do it yourself before calling.
		 */
		public function getTileType( r:int, c:int ):uint {
			return this.tiles[r][c].type;
		}

		public function get length():int {
			return this.rows * this.cols;
		} //

		/**
		 * clears all tiles and borders.
		 * 
		 * when using this function be sure to clear any partition/boundary collections of the tiles
		 * along with any information that depends on the way the tiles are filled. they're all gone now.
		 * 
		 * This function also resets the search index and cur_search id.
		 */
		public function clearAllTiles():void {

			var curRow:Vector.<LandTile>;

			for( var i:int = this._rows-1; i >= 0; i-- ) {

				curRow = this.tiles[i];

				for( var j:int = this._cols-1; j >= 0; j-- ) {

					curRow[j].type = 0;
					//tile.partition = tile.borders = 0
					//tile.type = tile.search_id = 0;

				} //

			} //

			//this.cur_search = 0;

		} //

		/**
		 * resets the cur_search and all tile search_ids to 0.
		 * Use if you think the cur_search might overflow, or if you're uncertain
		 * if all the tiles search_ids are properly marked.
		 */
		public function resetSearch():void {

			this.cur_search = 0;
			var curRow:Vector.<LandTile>;

			for( var i:int = this._rows-1; i >= 0; i-- ) {

				curRow = this.tiles[i];

				for( var j:int = this._cols-1; j >= 0; j-- ) {

					curRow[j].search_id = 0;

				} //

			} // for-loop.

		} // resetSearch()

		/**
		 * Adds all the neighbors of a current tile to a list of tiles.
		 */
		public function pushNeighbors( list:Vector.<LandTile>, r:int, c:int ):void {

			if ( r > 0 ) {
				list.push( this.tiles[r-1][c] );
			}
			if ( r+1 < this._rows ) {
				list.push( this.tiles[r+1][c] );
			}

			if ( c > 0 ) {
				list.push( this.tiles[r][c-1] );
			}
			if ( c+1 < this._cols ) {
				list.push( this.tiles[r][c+1] );
			}

		} //

		/**
		 * Adds a tile to the list if the tile exists and (tile.type & typeMask != 0)
		 * ( if the tile type is the same as the mask, it will be added to the list )
		 */
		public function pushTileIfType( list:Vector.<LandTile>, r:int, c:int, typeMask:uint=0xFFFFFF ):void {

			if ( r < 0 || r >= this._rows || c < 0 || c >= this._cols ) {
				return;
			}

			var t:LandTile = this.tiles[r][c];
			if ( (t.type & typeMask) != 0 ) {
				list.push( t );
			}

		} //

		/**
		 * Adds a tile to a list of tiles if the tile is empty.
		 */
		public function pushTileIfEmpty( list:Vector.<LandTile>, r:int, c:int ):void {

			if ( r < 0 || r >= this._rows || c < 0 || c >= this._cols ) {
				return;
			}

			var t:LandTile = this.tiles[r][c];
			if ( t.type == 0 ) {
				list.push( t );
			}

		} //
		
		/**
		 * Fast getTile() will return the tile at the given row,column of the map,
		 * but does not check if row,col are actually within range of the map.
		 * 
		 * For example, if the map has 3 rows and you request row 6, this function
		 * will break.
		 */
		
		final public function getTile( r:int, c:int ):LandTile
		{
			if(!this.tiles) 						return null; //No rows
			if(r < 0 || r >= this.tiles.length) 	return null; //Exceeds rows
			if(!this.tiles[r]) 						return null; //No columns
			if(c < 0 || c >= this.tiles[r].length) 	return null; //Exceeds columns
			return this.tiles[r][c];

		} //

		public function hasType( tile:LandTile, type:uint ):Boolean {
			
			if ( this.tileSet.allowMixedTiles ) {
				
				return ( (tile.type & type ) != 0 );
				
			} else {
				
				return ( tile.type == type );
				
			} //
			
		} //

		public function hasTypeAt( r:int, c:int, type:uint ):Boolean {
			
			if ( this.tileSet.allowMixedTiles ) {
				return ( (this.getTileType( r, c ) & type) != 0 );
			} else {
				return ( this.getTileType( r, c ) == type );
			}
			
		} //

		/**
		 * fill the given range with a tile type. if mixed tiles are allowed, the type is added to existing types.
		 * returns the count of tiles that were altered.
		 * 
		 * maxRow, maxCol are not affected - this is the stop range.
		 * 
		 * maxFills is a number greater than 0 that limits the number of tiles which will be filled.
		 */
		public function fillRange( row:int, col:int, maxRow:int, maxCol:int, type:uint, maxFills:int ):int {

			var c:int;
			var count:int = 0;
			var tile:LandTile;

			if ( row < 0 ) {
				row = 0;
			}
			if ( maxRow > this.rows ) {
				maxRow = this.rows;
			}
			if ( col < 0 ) {
				col = 0;
			}
			if ( maxCol > this.cols ) {
				maxCol = this.cols;
			}

			if ( this.tileSet.allowMixedTiles ) {

				while ( row < maxRow ) {

					for( c = col; c < maxCol; c++ ) {

						tile = this.tiles[row][c];

						if ( (tile.type & type) == 0 ) {

							this.tiles[row][c].type |= type;
							if ( ++count >= maxFills ) {
								return count;
							}

						} //

					} //

					row++;

				} //

			} else {

				while ( row < maxRow ) {

					for( c = col; c < maxCol; c++ ) {

						tile = this.tiles[row][c];
						if ( tile.type != type ) {

							this.tiles[row][c].type = type;
							if ( ++count >= maxFills ) {
								return count;
							}

						}

					} // for-loop.

					row++;

				} //

			} //

			return count;

		} //

		/**
		 * remove a single tile type from a given range.
		 * !!! maxRow, maxCol are not affected - this is the stop range.
		 * returns the count of the number of tiles that had to be changed.
		 */
		public function clearTypeRange( row:int, col:int, maxRow:int, maxCol:int, type:uint ):int {

			var c:int;
			var count:int = 0;
			var tile:LandTile;

			if ( row < 0 ) {
				row = 0;
			}
			if ( maxRow > this.rows ) {
				maxRow = this.rows;
			}
			if ( col < 0 ) {
				col = 0;
			}
			if ( maxCol > this.cols ) {
				maxCol = this.cols;
			}

			if ( this.allowMixedTiles ) {
	
				while ( row < maxRow ) {
		
					for( c = col; c < maxCol; c++ ) {
	
						tile = this.tiles[row][c];
						if ( (tile.type & type) != 0 ) {
	
							count++;
							tile.type ^= type;
						}
	
					} //
	
					row++;
	
				} // while-loop.

			} else {

				while ( row < maxRow ) {
					
					for( c = col; c < maxCol; c++ ) {
						
						tile = this.tiles[row][c];
						if ( tile.type == type ) {
							
							count++;
							tile.type = 0;
						}
						
					} //
					
					row++;
					
				} // while-loop.

			} //

			return count;

		} //

		public function getTypeAt( r:int, c:int ):TileType {
			
			var tileCode:uint = this.getTileType( r, c );

			if ( this.tileSet.allowMixedTiles == true ) {

				var codeBit:uint = 1;
				
				// tileCodes are OR-d combinations.
				while ( tileCode > 0 ) {
					
					if ( codeBit & tileCode ) {
						return this.tileSet.typesByCode[ codeBit ];
					}
					
					codeBit <<= 1;
					
				} //
				
				return null;
				
			} else {
				
				return this.tileSet.typesByCode[ tileCode ];

			} //
			
		} //

		[Inline]
		final public function getType( tile:LandTile ):TileType {

			return this.tileSet.getType( tile );

		} //

		/**
		 * 
		 * returns an array of all tile types at the given x,y location.
		 * There will only be a single tile type unless allowMixedTiles == true
		 * 
		 */
		public function getTypesAt( r:Number, c:Number ):Array {

			var tileCode:uint = this.getTileType( r, c );

			if ( this.tileSet.allowMixedTiles == true ) {

				var a:Array = new Array();
				var codeBit:uint = 1;

				// tileCodes are OR-d combinations.
				while ( tileCode > 0 ) {

					if ( codeBit & tileCode ) {
						a.push( this.tileSet.typesByCode[ codeBit ] );
					}
					tileCode ^= codeBit;
					codeBit <<= 1;
					
				} //
				
				return a;
				
			} else {

				return [ this.tileSet.typesByCode[ tileCode ] ];
				
			} //
			
		} //

		/**
		 * Adds a number of rows to the top of the tile map. This means the current tiles
		 * need to be pushed down and have their row indices incremented.
		 */
		public function addTopRows( numRows:int ):void {
			
			var curRow:Vector.<LandTile>;
			
			// Increment the row indices of all existing tiles.
			for( var i:int = this.tiles.length-1; i >= 0; i-- ) {
				
				curRow = this.tiles[i];
				for( var j:int = cols-1; j >= 0; j-- ) {
					curRow[j].row += numRows;
				} //
				
			} //
			
			// now add the new empty rows.
			for( i = numRows-1; i >= 0; i-- ) {
				
				curRow = new Vector.<LandTile>( this._cols );
				
				for( j = this._cols-1; j >= 0; j-- ) {
					curRow[j] = new LandTile( i, j );
				} //
				
				this.tiles.unshift( curRow );
				
			} //
			
			this._rows += numRows;
			
		} //
		
		/**
		 * Adds a number of rows to the bottom of the tiling. This is cheaper than expanding
		 * the top, but unlikely to be useful in the case of land tilings.
		 */
		public function addRows( numRows:int ):void {

			var curRow:Vector.<LandTile>;
			var tile:LandTile;
			var jiggle:Number = this.tileSize/10;

			// add the new empty rows.
			for( var i:int = 0; i < numRows; i++ ) {

				curRow = new Vector.<LandTile>( this._cols );

				for( var j:int = this._cols-1; j >= 0; j-- ) {

					curRow[j] = tile = new LandTile( this._rows + i, j );
					tile.jiggle( jiggle );

				} //

				this.tiles.push( curRow );

			} //

			this._rows += numRows;
			
		} //

		public function addCols( numCols:int ):void {

			var tileRow:Vector.<LandTile>;
			var tile:LandTile;
			var jiggle:Number = this.tileSize/10;

			var newCols:int = numCols + this._cols;

			for( var r:int = 0; r < this._rows; r++ ) {

				tileRow = this.rows[r];
				tileRow.length = newCols;

				for( var c:int = this._cols; c < newCols; c++ ) {
					tileRow[c] = tile = new LandTile( r, c );
					tile.jiggle( jiggle );
				} //

			} // for-loop.

		} //

		/**
		 * resize the tilemap.
		 */
		public function resize( newRows:int, newCols:int ):void {

			if ( newRows > _rows ) {

				this.addRows( newRows - rows );

			} else if ( newRows < _rows ) {

				this.tiles.length = newRows;
				this._rows = newRows;

			} //

			if ( newCols != this._cols ) {

				var tileRow:Vector.<LandTile>;
				var tile:LandTile;
				var jiggle:Number = this.tileSize/10;

				for( var r:int = 0; r < this._rows; r++ ) {
					
					tileRow = this.tiles[r];
					tileRow.length = newCols;

					// add any new columns, if necessary.
					for( var c:int = this._cols; c < newCols; c++ ) {

						tileRow[c] = tile = new LandTile( r, c );
						tile.jiggle( jiggle );

					} //
					
				} // for-loop.

				this._cols = newCols;

			} // (newCols!=cols)

		} //

		/**
		 * only use this function when loading tiles from data.
		 */
		public function setTiles( newTiles:Vector.< Vector.<LandTile> > ):void {

			this.tiles = newTiles;
			this._rows = newTiles.length;

			if ( _rows > 0 ) {

				this._cols = newTiles[0].length;

			} else {

				// this should not happen.
				this._cols = 0;

			} //

		} //

		public function getTileLoc( tile:LandTile ):Point {

			return new Point( tile.col*this.tileSize, tile.row*this.tileSize );

		} //

		public function getTileAt( x:Number, y:Number ):LandTile {

			return this.getTile( Math.floor( y / this.tileSize ), Math.floor( x / this.tileSize ) );

		} //

		public function getTiles():Vector.< Vector.<LandTile> > {
			return this.tiles;
		}

		/**
		 * this is used by several renderers to check if a tile border should use a slope.
		 * the reason its here is because several renderers use it. although it could go in the MapRenderer superclass too.
		 * 
		 * emptyRow, emptyCol is the empty space adjacent to two tiles of the same type between which a slope might be drawn.
		 * 
		 * jordan's test for drawing slopes is that extending the slope in either direction must hit a tileType different
		 * from the current one. also there is a maximum number of border tiles allowed.
		 * 
		 */
		public function canDrawSlope( emptyRow:int, emptyCol:int, dr:int, dc:int, tileType:uint ):Boolean {

			if ( this.countNeighborsOfType( emptyRow, emptyCol, tileType ) >= 3 ) {
				return false;
			}

			var r:int = emptyRow + dr;
			// first test that extending the slope in at least one direction will yield a tileType other than the current one.
			// this is jordan's condition for drawing slopes.
			
			if (r < 0 || r >= this.rows ) {
				return true;						// tiles offscreen will be treated as empty/distinct.
			}

			var c:int = emptyCol + dc;
			if ( c < 0 || c >= this.cols ) {
				return true;
			} //
			
			// jordan's condition of the extended slope being different is satisfied. draw a diagonal.
			if ( this.tiles[r][c].type != tileType ) {
				return true;
			}

			// now test the back diagonal.
			r = emptyRow - dr;
			
			if (r < 0 || r >= this.rows ) {
				return true;						// tiles offscreen will be treated as empty/distinct.
			}
			
			c = emptyCol - dc;
			if ( c < 0 || c >= this.cols ) {
				return true;
			} //
			
			// jordan's condition of the extended slope being different is satisfied. draw a diagonal.
			if ( this.tiles[r][c].type != tileType ) {
				return true;
			}
			
			return false;
			
		} //

		public function countNeighborsOfType( r:int, c:int, type:uint ):int {
	
			var count:int = 0;

			if ( r > 0 && this.tiles[r-1][c].type == type ) {
				count++;
			}
			if ( r+1 < this._rows && this.tiles[r+1][c].type == type ) {
				count++;
			}
			if ( c > 0 && this.tiles[r][c-1].type == type ) {
				count++;
			}
			if ( c+1 < this._cols && this.tiles[r][c+1].type == type ) {
				count++;
			}

			return count;

		} //

		/**
		 * copies this tile map into the destination tile map at the given startRow, startCol of the destination.
		 * 
		 * startRow, startCol must be a valid row,col in the destination tileMap.
		 */
		public function copyTo( destMap:TileMap, startRow:int, startCol:int ):void {
			
			var destTiles:Vector.< Vector.<LandTile> >  = destMap.getTiles();
			
			var maxRow:int = this._rows;
			if ( startRow + maxRow >= destTiles.length ) {
				maxRow = destTiles.length - startRow;
			}
			
			var maxCol:int = this._cols;
			if ( startCol + maxCol >= destMap.cols ) {
				maxCol = destMap.cols - startCol;
			}
			
			for( var r:int = maxRow-1; r >= 0; r-- ) {
				
				for( var c:int = maxCol-1; c >= 0; c-- ) {
					
					destTiles[ startRow + r ][ startCol + c ].type = this.tiles[r][c].type;

				} //

			} // for-loop.

		} //

		/**
		 * copies this tile map into the destination tile map at the given startRow, startCol of the destination.
		 * identical to copyTo() function but also copies. the jiggleX,Y values of the source tiles.
		 */
		public function copyToWithJiggle( destMap:TileMap, startRow:int, startCol:int ):void {
			
			var destTiles:Vector.< Vector.<LandTile> > = destMap.getTiles();
			var dest:LandTile;
			var src:LandTile;

			var maxRow:int = this._rows;
			if ( startRow + maxRow >= destTiles.length ) {
				maxRow = destTiles.length - startRow;
			}
			
			var maxCol:int = this._cols;
			if ( startCol + maxCol >= destMap.cols ) {
				maxCol = destMap.cols - startCol;
			}
			
			for( var r:int = maxRow-1; r >= 0; r-- ) {

				for( var c:int = maxCol-1; c >= 0; c-- ) {

					src = this.tiles[r][c];
					dest = destTiles[ startRow + r ][ startCol + c ];

					dest.type = src.type;
					if ( src.type != 0 ) {
						dest.tileDataX = src.tileDataX;
						dest.tileDataY = src.tileDataY;
					}
					
				} //
				
			} // for-loop.
			
		} //

		/**
		 * copies the src map into this tile map, beginning at the startRow, startCol of the source map.
		 */
		public function copyFrom( srcMap:TileMap, startRow:int, startCol:int ):void {
			
			var srcTiles:Vector.< Vector.<LandTile> >  = srcMap.getTiles();
			
			var maxRow:int = this._rows;
			if ( startRow + maxRow >= srcTiles.length ) {
				maxRow = srcTiles.length - startRow;
			}
			
			var maxCol:int = this._cols;
			if ( startCol + maxCol >= srcMap.cols ) {
				maxCol = srcMap.cols - startCol;
			}
			
			for( var r:int = maxRow-1; r >= 0; r-- ) {

				for( var c:int = maxCol-1; c >= 0; c-- ) {

					this.tiles[r][c].type = srcTiles[ startRow + r ][ startCol + c ].type;

				} //

			} // for-loop.

		} //

		/**
		 * this copies from a source map that is a Decal-type tile map.
		 * 
		 * this keeps the jiggle factor ( which in decal maps indicates decal-clip-offset )
		 */
		public function copyFromDecal( srcMap:TileMap, startRow:int, startCol:int ):void {
			
			var srcTiles:Vector.< Vector.<LandTile> >  = srcMap.getTiles();

			var dest:LandTile;
			var src:LandTile;

			var maxRow:int = this._rows;
			if ( startRow + maxRow >= srcTiles.length ) {
				maxRow = srcTiles.length - startRow;
			}
			
			var maxCol:int = this._cols;
			if ( startCol + maxCol >= srcMap.cols ) {
				maxCol = srcMap.cols - startCol;
			}
			
			for( var r:int = maxRow-1; r >= 0; r-- ) {
				
				for( var c:int = maxCol-1; c >= 0; c-- ) {

					dest = this.tiles[r][c];
					src = srcTiles[ startRow + r ][ startCol + c ];
	
					dest.type = src.type;
					dest.tileDataX = src.tileDataX;
					dest.tileDataY = src.tileDataY;
					
				} //
				
			} // for-loop.
			
		} //

		/**
		 * Finds all tileTypes that are being used in this tileMap whose display resouces have not been loaded.
		 * This function DOES NOT WORK for tileMaps with multi-tile sets.
		 * 
		 * The tileTypes that need to be loaded are placed in a dictionary so there's a quick check to see
		 * if they're already in the load list.
		 * Returns true if tiles exist that must be loaded.
		 */
		public function findUnloadedTiles( loadDict:Dictionary, fromSet:TileSet=null ):Boolean {

			var typesById:Dictionary;
			if ( fromSet ) {
				typesById = fromSet.typesByCode;
			} else {
				typesById = this.tileSet.typesByCode;
			}

			var typeCode:uint;
			var tileType:TileType;

			var hasLoads:Boolean = false;

			for( var r:int = this._rows-1; r >= 0; r-- ) {

				for( var c:int = this._cols-1; c >= 0; c-- ) {

					typeCode = this.tiles[r][c].type;

					if ( typeCode == 0 ) {
						continue;
					}

					tileType = typesById[ typeCode ];
					if ( tileType == null ) {
						// no tileType with the matching type code for this tile. something went wrong. clear the tile.
						this.tiles[r][c].type = 0;
					} else if ( tileType.image == null ) {
						loadDict[ tileType ] = tileType;
						hasLoads = true;
					} //

				} // for-loop.

			} // for-loop.

			return hasLoads;

		} //

		public function get rows():int {
			return this._rows;
		}
		
		public function get cols():int {
			return this._cols;
		}

		public function get allowMixedTiles():Boolean {
			return this.tileSet.allowMixedTiles;
		}

		public function destroy():void {
			
			for( var r:int = this._rows-1; r >= 0; r-- ) {
				this.tiles[r].length = 0;
			}
			this.tiles.length = 0;
			this.tiles = null;
			
			for( var i:int = this.renderers.length-1; i >= 0; i-- ) {
				this.renderers[i].destroy();
			} //
			this.renderers = null;
			
			for( i = this.generators.length-1; i >= 0; i-- ) {
				this.generators[i].destroy();
			} //
			this.generators = null;
			
		} //

	} // End TileMap
	
} // End package