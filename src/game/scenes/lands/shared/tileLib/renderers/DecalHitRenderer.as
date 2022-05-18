package game.scenes.lands.shared.tileLib.renderers {

	/**
	 * does outline hit rendering for decals. only draws hit. no view.
	 * 
	 */

	import flash.display.BitmapData;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.getTimer;
	
	import game.scenes.lands.shared.tileLib.LandTile;
	import game.scenes.lands.shared.tileLib.TileMap;
	import game.scenes.lands.shared.tileLib.painters.OutlineHitPainter;
	import game.scenes.lands.shared.tileLib.painters.RenderContext;
	import game.scenes.lands.shared.tileLib.tileSets.TileSet;
	import game.scenes.lands.shared.tileLib.tileTypes.TileType;


	public class DecalHitRenderer extends MapRenderer {

		private var tileTypes:Vector.<TileType>;
		private var curTileType:TileType;

		// used to track points for drawing.
		private var curPoint:Point;
		private var nextPoint:Point;

		private var painter:OutlineHitPainter;

		private var tileSet:TileSet;

		public function DecalHitRenderer( tmap:TileMap, rc:RenderContext ) {

			super( tmap, rc );

			this.tileSet = this.tileMap.tileSet;
			this.tileTypes = this.tileSet.tileTypes;

			// stuff used for drawing.
			this.curPoint = new Point();
			this.nextPoint = new Point();

			this.painter = new OutlineHitPainter( rc );

		} //

		/**
		 * 
		 * temporary function till I figure a better way to do this.
		 * Render the data from a template using the given view. The tileSet, tileSize data doesn't change.
		 * 
		 */
		override public function prepareTemplate( templateMap:TileMap, templateView:BitmapData ):void {
			
			this.tileMap = templateMap;

			this.painter.drawHits = false;

		} //

		override public function render():void {

			//var t1:Number = getTimer();

			this.painter.startPaintBatch();

			this.drawLocal( 0, 0, this.tileMap.rows-1, this.tileMap.cols-1 );

			this.painter.endPaintBatch();

			//var t2:Number = getTimer();
			//trace( "DECAL HIT RENDER TIME: " + (t2-t1) );

		} //

		override public function renderArea( eraseRect:Rectangle ):void {

			this.painter.startPaintBatch();

			var minRow:int = Math.floor( eraseRect.y / this.tileSize) - 1;
			var maxRow:int = Math.ceil( eraseRect.bottom / this.tileSize );
			var minCol:int = Math.floor( eraseRect.x / this.tileSize )-1;
			var maxCol:int = Math.ceil( eraseRect.right / this.tileSize );

			if ( minRow < 0 ) {
				minRow = 0;
			}
			if ( maxRow >= this.tileMap.rows ) {
				maxRow = this.tileMap.rows-1;
			} //
			if ( minCol < 0 ) {
				minCol = 0;
			}
			if ( maxCol >= this.tileMap.cols ) {
				maxCol = this.tileMap.cols-1;
			} //

			this.drawLocal( minRow, minCol, maxRow, maxCol );
			
			this.painter.endPaintBatch();

		} //

		/**
		 * far more efficient method of updating a tile that has been changed, by only drawing
		 * tiles that are nearby. this makes the border-drawing logic a bit more complex, but
		 * keeps all single-tile-redraws down to constant time.
		 */
		private function drawLocal( minRow:int, minCol:int, maxRow:int, maxCol:int ):void {

			var tile:LandTile;

			this.tileMap.beginSearch();

			var tiles:Vector.<Vector.<LandTile>> = this.tileMap.getTiles();
			var tileRow:Vector.<LandTile>;

			for( var r:int = minRow; r <= maxRow; r++ ) {

				tileRow = tiles[r];

				for( var c:int = minCol; c <= maxCol; c++ ) {

					tile = tileRow[c];

					if ( tile.type == 0 ) {
						continue;
					} else if ( tile.search_id < this.tileMap.cur_search ) {

						// first time seeing this tile in this search.
						// need to mark the borders as not being drawn, in case they had been drawn in a previous render.
						tile.drawnBorders = 0;
						tile.search_id = this.tileMap.cur_search;

					}

					// A lot of new, confusing code here. Basically need to find the tiles that have borders.
					if ( !(tile.drawnBorders & LandTile.RIGHT) &&
						( c == maxCol || tileRow[c+1].type == 0 ) ) {
						this.drawBorder( tile, LandTile.RIGHT, minRow, minCol, maxRow, maxCol );
					}
					if ( !(tile.drawnBorders & LandTile.LEFT) &&
						( c == minCol || tileRow[c-1].type == 0 ) ) {
						this.drawBorder( tile, LandTile.LEFT, minRow, minCol, maxRow, maxCol );
					}
					if ( !(tile.drawnBorders & LandTile.TOP) &&
						( r == minRow || tiles[r-1][c].type == 0 ) ) {
						this.drawBorder( tile, LandTile.TOP, minRow, minCol, maxRow, maxCol );
					}
					if ( !(tile.drawnBorders & LandTile.BOTTOM) && 
						( r == maxRow || tiles[r+1][c].type == 0 ) ) {
						this.drawBorder( tile, LandTile.BOTTOM, minRow, minCol, maxRow, maxCol );
					}

				} // for-column loop.

			} // for-row loop.

		} // drawLocal()

		/**
		 * The border of a region of tiles, bounded within the given row,col limits.
		 * 
		 * Drawing is done in a clockwise direction so current drawing borders always start at the counter-clockwise edge of a tile side.
		 * so if you're currently at the TOP border, youll start at TOP-LEFT and go to the TOP-RIGHT
		 */
		private function drawBorder( startTile:LandTile, startBorder:uint, minRow:int, minCol:int, maxRow:int, maxCol:int ):void {

			var tile:LandTile = startTile;
			var curBorder:uint = startBorder;

			var nextTile:LandTile;
			var nextBorder:uint;

			var nextTileFound:Boolean;

			this.beginBorder( tile, curBorder, this.curPoint );
			var curType:int = this.curTileType.type;

			do {

				tile.drawnBorders |= curBorder;
				nextTileFound = false;

				if ( curBorder == LandTile.TOP ) {

					this.getTopRight( tile, this.nextPoint );

					if ( tile.col < maxCol ) {
						if ( tile.row > minRow ) {					// try top-right tile.
	
							nextTile = this.tileMap.getTile( tile.row-1, tile.col+1 );
							if ( nextTile.type == curType ) {
	
								nextBorder = LandTile.LEFT;
								nextTileFound = true;
	
							} //
						}
						if ( !nextTileFound ) {					// try tile to the right.
							nextTile = this.tileMap.getTile( tile.row, tile.col+1 );
							if ( nextTile.type == curType ) {
								nextBorder = LandTile.TOP;
								nextTileFound = true;
							}
						}

					}

					if ( !nextTileFound ) {
						nextTile = tile;
						nextBorder = LandTile.RIGHT;
					}
					
				} else if ( curBorder == LandTile.RIGHT ) {

					this.getBottomRight( tile, this.nextPoint );

					if ( tile.row < maxRow && tile.col < maxCol ) {

						nextTile = this.tileMap.getTile( tile.row+1, tile.col+1 );
						if ( nextTile.type == curType ) {

							nextBorder = LandTile.TOP;
							nextTileFound = true;

						}

					}
					if ( !nextTileFound && tile.row < maxRow ) {
						nextTile = this.tileMap.getTile( tile.row+1, tile.col );
						if ( nextTile.type == curType ) {
							nextBorder = LandTile.RIGHT;
							nextTileFound = true;
						}
					}
					if ( !nextTileFound ) {
						nextTile = tile;
						nextBorder = LandTile.BOTTOM;
					}

				} else if ( curBorder == LandTile.BOTTOM ) {

					this.getBottomLeft( tile, this.nextPoint );

					if ( tile.row < maxRow && tile.col > minCol ) {
						
						nextTile = this.tileMap.getTile( tile.row+1, tile.col-1 );
						if ( nextTile.type == curType ) {
							nextBorder = LandTile.RIGHT;
							nextTileFound = true;

						}
						
					}
					if ( !nextTileFound && tile.col > minCol ) {
						nextTile = this.tileMap.getTile( tile.row, tile.col-1 );
						if ( nextTile.type == curType ) {
							nextBorder = LandTile.BOTTOM;
							nextTileFound = true;
						}
					}
					if ( !nextTileFound ) {
						nextTile = tile;
						nextBorder = LandTile.LEFT;
					}
					
				} else {

					this.getTopLeft( tile, this.nextPoint );

					if ( tile.row > minRow && tile.col > minCol ) {

						nextTile = this.tileMap.getTile( tile.row-1, tile.col-1 );
						if ( nextTile.type == curType ) {

							nextBorder = LandTile.BOTTOM;
							nextTileFound = true;

						}
						
					}
					if ( !nextTileFound && tile.row > minRow ) {
						nextTile = this.tileMap.getTile( tile.row-1, tile.col );
						if ( nextTile.type == curType ) {
							nextBorder = LandTile.LEFT;
							nextTileFound = true;
						}
					}
					if ( !nextTileFound ) {
						nextTile = tile;
						nextBorder = LandTile.TOP;
					}

				} // end-if.

				if ( this.curTileType.drawHits ) {
					this.painter.lineStroke( nextPoint.x, nextPoint.y, curBorder, this.curTileType );
				}

				tile = nextTile;
				curBorder = nextBorder;

				if ( tile.search_id < this.tileMap.cur_search ) {
					tile.search_id = this.tileMap.cur_search;
					tile.drawnBorders = 0;
				}

			} while ( (tile != startTile) || (curBorder != startBorder) );

		} //

		/**
		 */
		protected function beginBorder( tile:LandTile, border:uint, p:Point ):void {

			this.curTileType = this.tileSet.getTypeByCode( tile.type );

			if ( border == LandTile.TOP ) {

				this.getTopLeft( tile, p );


			} else if ( border == LandTile.RIGHT ) {

				this.getTopRight( tile, p );

			} else if ( border == LandTile.BOTTOM ) {

				this.getBottomRight( tile, p )


			} else {

				//  BORDER LEFT
				this.getBottomLeft( tile, p );

			} //

			this.painter.startStroke( p.x, p.y );

		} //

		override public function setRenderContext( rc:RenderContext ):void {

			this.painter.setRenderContext( rc );

		} //

		public function set drawHits( b:Boolean ):void {

			this.painter.drawHits = b;

		} //

		private function getTopLeft( tile:LandTile, p:Point ):void {

			p.x = tile.col*this.tileSize;
			p.y = tile.row*this.tileSize;

		} //

		private function getTopRight( tile:LandTile, p:Point ):void {

			p.x = ( tile.col + 1 )*this.tileSize;
			p.y = ( tile.row )*this.tileSize;

		} //

		private function getBottomLeft( tile:LandTile, p:Point ):void {

			p.x = ( tile.col )*this.tileSize;
			p.y = ( tile.row + 1 )*this.tileSize;

		} //

		private function getBottomRight( tile:LandTile, p:Point ):void {

			p.x = ( tile.col + 1 )*this.tileSize;
			p.y = ( tile.row + 1 )*this.tileSize;

		} //

	} // End class

} // End package