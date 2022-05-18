package game.scenes.lands.shared.tileLib.generation.generators {

	import game.scenes.lands.shared.classes.LandGameData;
	import game.scenes.lands.shared.tileLib.LandTile;
	import game.scenes.lands.shared.tileLib.TileMap;
	import game.scenes.lands.shared.tileLib.classes.RandomMap;
	import game.scenes.lands.shared.tileLib.tileSets.TileSet;

	public class MapGenerator {

		public var pass:int = 1;

		protected var tileSet:TileSet;
		protected var tileMap:TileMap;

		protected var randomMap:RandomMap;

		public function MapGenerator( tmap:TileMap=null ) {

			if ( tmap ) {
				this.tileMap = tmap;
				this.tileSet = tmap.tileSet;
			}

		} //

		/**
		 * subclasses override this function to generate their land tiles.
		 */
		public function generate( gameData:LandGameData=null ):void {
		} //

		/**
		 * a tile is a top tile if the tile is filled but the tile above is empty. for the sake of exactness
		 * tiles on the very top of the map are not considered top tiles - there is no room for features above.
		 */
		protected function isTopTileAt( tMap:TileMap, r:int, c:int ):Boolean {

			if ( r <= 0 || tMap.getTileType( r, c ) == 0 || tMap.getTileType( r-1, c ) != 0 ) {
				return false;
			}

			return true;

		} //

		/**
		 * goes from the top row of the tile map at the current column, and returns the row
		 * of the first non-empty tile.
		 * returns -1 if no non-empty tile.
		 */
		protected function getTopRow( tMap:TileMap, c:int ):int {

			var r:int = 2;
			var max:int = tMap.rows-1;

			for( ; r < max; r++ ) {

				if ( tMap.getTileType( r, c ) > 0 ) {
					return r;
				}

			} //

			return -1;

		} //

		protected function getTopTile( tMap:TileMap, c:int ):LandTile {

			var tile:LandTile;

			var r:int = 2;
			var max:int = tMap.rows-1;
			
			for( ; r < max; r++ ) {

				tile = tMap.getTile( r, c );
				if ( tile.type != 0 ) {
					return tile;
				}

			} //
			
			return null;

		} //

		protected function isTopTypeAt( tMap:TileMap, r:int, c:int, type:uint ):Boolean {
			
			if ( r <= 0 || tMap.getTileType( r, c ) != type || tMap.getTileType( r-1, c ) != 0 ) {
				return false;
			}
			
			return true;
			
		} //

		protected function isTopTile( tMap:TileMap, tile:LandTile ):Boolean {
			
			if ( tile.type == 0 || tile.row <= 0 || tMap.getTileType( tile.row-1, tile.col ) != 0 ) {
				return false;
			}
			
			return true;
			
		} //

		protected function getRandomTile():LandTile {

			if ( this.randomMap ) {
				return this.tileMap.getTile( Math.floor(this.randomMap.getRandom()*this.tileMap.rows),
						Math.floor( this.randomMap.getRandom()*this.tileMap.cols ) );
			} else {
				return this.tileMap.getTile( Math.floor( Math.random()*this.tileMap.rows ), Math.floor( Math.random()*this.tileMap.cols ) );
			}

		} //

		/**
		 * when getting random tiles with specific qualities, like empty or filled, there are two function types:
		 * tryRandom and getRandom.
		 * 
		 * tryRandomEmpty() will just try randomly getting a tile a certain number of times.
		 * getRandomEmpty() will absolutely find a random empty tile if one exists.
		 * 
		 * either function may return null if no tiles of the correct type are found.
		 * 
		 * the other functions are similar.
		 */
		protected function tryRandomEmpty( maxTries:int=10):LandTile {

			var tile:LandTile;

			if ( this.randomMap ) {

				while ( maxTries-- > 0 ) {

					tile = this.tileMap.getTile( Math.floor(this.randomMap.getRandom()*this.tileMap.rows),
							Math.floor( this.randomMap.getRandom()*this.tileMap.cols ) );
					
					if ( tile.type == 0 ) {
						return tile;
					}

				} //

			} else {

				while ( maxTries-- > 0 ) {
					
					tile = this.tileMap.getTile( Math.floor( Math.random()*this.tileMap.rows ), Math.floor( Math.random()*this.tileMap.cols ) );
				
					if ( tile.type == 0 ) {
						return tile;
					}
					
				} //
	
			}

			return null;

		} //

		/**
		 * note the problem with this function is that when it doesn't find a given tile, it always looked for a new tile in a 'forward'
		 * direction. this will skew the results statistically. slightly better would be to search for a new tile in some arbitrary
		 * compass direction, but who really cares?
		 */
		protected function getRandomEmpty( tMap:TileMap=null ):LandTile {
			
			var tile:LandTile;
			
			if ( tMap == null ) {
				tMap = this.tileMap;
			}
			
			if ( this.randomMap ) {
				
				tile = tMap.getTile( Math.floor(this.randomMap.getRandom()*tMap.rows),
					Math.floor( this.randomMap.getRandom()*tMap.cols ) );
				
			} /*else {
				
				tile = tMap.getTile( Math.floor( Math.random()*tMap.rows ), Math.floor( Math.random()*tMap.cols ) );
				
			}*/
			
			if ( tile.type == 0 ) {
				return tile;
			}
			
			// number of tiles we could try.
			var count:int = tMap.rows*tMap.cols - 1;
			var row:int = tile.row;
			var col:int = tile.col;

			do {

				// note that we check additional rows before columns. searching for a tile - say grass - in a horizontal
				// order tends to select the same grass tile each time.
				if ( ++row >= tMap.rows ) {
					row = 0;
					if ( ++col >= tMap.cols ) {
						col = 0;
					}
				}
				tile = tMap.getTile( row, col );
				if ( tile.type == 0 ) {
					return tile;
				}
				
			} while ( --count > 0 );
			
			return null;
			
		} //

		protected function tryRandomFilled( tMap:TileMap=null, maxTries:int=10 ):LandTile {
			
			var tile:LandTile;

			if ( tMap == null ) {
				tMap = this.tileMap;
			}
			
			if ( this.randomMap ) {
				
				while ( maxTries-- > 0 ) {
					
					tile = tMap.getTile( Math.floor(this.randomMap.getRandom()*tMap.rows),
						Math.floor( this.randomMap.getRandom()*tMap.cols ) );
					
					if ( tile.type != 0 ) {
						return tile;
					}
					
				} //
				
			}
			
			return null;
			
		} //

		// get a random tile with the given tile type.
		protected function tryRandomType( tMap:TileMap=null, findType:uint=0, maxTries:int=10 ):LandTile {
			
			var tile:LandTile;

			if ( tMap == null ) {
				tMap = this.tileMap;
			}
			
			if ( this.randomMap ) {
				
				while ( maxTries-- > 0 ) {
					
					tile = tMap.getTile( Math.floor(this.randomMap.getRandom()*tMap.rows),
						Math.floor( this.randomMap.getRandom()*tMap.cols ) );

					if ( tile.type == findType ) {
						return tile;
					}
					
				} //
				
			}
			
			return null;
			
		} //

		/**
		 * returns a random tile with the given tileType.
		 */
		protected function getRandomWithType( tMap:TileMap=null, findType:uint=0 ):LandTile {
			
			var tile:LandTile;

			if ( tMap == null ) {
				tMap = this.tileMap;
			}

			if ( this.randomMap ) {
				
				tile = tMap.getTile( Math.floor(this.randomMap.getRandom()*tMap.rows),
					Math.floor( this.randomMap.getRandom()*tMap.cols ) );

			}
	
			if ( tile.type == findType ) {
				return tile;
			}
			
			// number of tiles we could try.
			var count:int = tMap.rows*tMap.cols - 1;
			var row:int = tile.row;
			var col:int = tile.col;

			do {

				if ( ++row >= tMap.rows ) {
					row = 0;
					if ( ++col >= tMap.cols ) {
						col = 0;
					}
				}
				tile = tMap.getTile( row, col );
				if ( tile.type == findType ) {
					return tile;
				}

			} while ( --count > 0 );
			
			return null;
			
		} //

		protected function isNonEmptyInRect( minRow:int, maxRow:int, minCol:int, maxCol:int, tMap:TileMap=null ):Boolean {

			if ( tMap == null ) {
				tMap = this.tileMap;
			}

			if ( minRow < 0 ) {
				minRow = 0;
			}
			if ( maxRow >= tMap.rows ) {
				maxRow = tMap.rows-1;
			}
			if ( minCol < 0 ) {
				minCol = 0;
			}
			if ( maxCol >= tMap.cols ) {
				maxCol = tMap.cols-1;
			}
			
			for( var r:int = minRow; r <= maxRow; r++ ) {
				
				for( var c:int = minCol; c <= maxCol; c++ ) {
					
					if ( tMap.getTileType( r, c ) != 0 ) {
						return true;
					}
					
				} //
				
			} // for-loop.
			
			return false;
			
		} // ()

		// checks if there are any tiles of the given type within the rect specified.
		// the keyword 'mixed' here indicates the bitCode of the type has to occur in the found tile.
		protected function isMixedTypeInRect( minRow:int, maxRow:int, minCol:int, maxCol:int, type:uint=0, tMap:TileMap=null ):Boolean {

			if ( tMap == null ) {
				tMap = this.tileMap;
			}

			if ( minRow < 0 ) {
				minRow = 0;
			}
			if ( maxRow >= tMap.rows ) {
				maxRow = tMap.rows-1;
			}
			if ( minCol < 0 ) {
				minCol = 0;
			}
			if ( maxCol >= tMap.cols ) {
				maxCol = tMap.cols-1;
			}

			for( var r:int = minRow; r <= maxRow; r++ ) {

				for( var c:int = minCol; c <= maxCol; c++ ) {

					if ( (tMap.getTileType( r, c ) & type) > 0 ) {
						return true;
					}

				} //

			} // for-loop.

			return false;

		} // isMixedTypeInRect()

		/**
		 * fills a circle centered at row,col with the given tile type.
		 */
		protected function fillCircle( row:int, col:int, radius:Number, type:uint ):void {

			var r2:Number = radius*radius;
			var d2:Number;
			var rmax:int, cmax:int;
			
			if ( row + radius >= this.tileMap.rows ) {
				rmax = this.tileMap.rows - row - 1;
			} else {
				rmax = radius;
			}
			
			if ( col + radius >= this.tileMap.cols ) {
				cmax = this.tileMap.cols - col - 1;
			} else {
				cmax = radius;
			}
			
			// if row or col < radius then Math.max( -row ) > Math.max(-radius)
			for( var dr:int = Math.max( -row, -radius ); dr <= rmax; dr++ ) {
				
				for( var dc:int = Math.max( -col, -radius ); dc <= cmax; dc++ ) {
					
					d2 = dr*dr + dc*dc;
					if ( d2 <= r2 && this.randomMap.getRandom() > (d2/r2) ) { 
						this.tileMap.getTile( row + dr, col + dc ).type |= type;
					} //

				} //

			} // for-loop.

		} // fillCircle()

		public function setRandomMap( randomMap:RandomMap ):void {

			this.randomMap = randomMap;

		} //

		public function destroy():void {
		} //

	} // End MapGenerator

} // End package