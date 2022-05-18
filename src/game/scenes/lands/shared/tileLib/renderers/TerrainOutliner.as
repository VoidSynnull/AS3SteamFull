package game.scenes.lands.shared.tileLib.renderers {

	/**
	 * outlines an entire terrain, regardless of tile types.
	 */

	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import game.scenes.lands.shared.tileLib.LandTile;
	import game.scenes.lands.shared.tileLib.TileMap;
	import game.scenes.lands.shared.tileLib.painters.OutlinePainter;
	import game.scenes.lands.shared.tileLib.painters.RenderContext;
	import game.scenes.lands.shared.tileLib.tileSets.TileSet;

	public class TerrainOutliner extends MapRenderer {

		/**
		 * Points to reuse in algorithms instead of allocating new points over and over.
		 * Typically these are midpoints on the edges of the current tiles being drawn.
		 */
		protected var curPoint:Point;
		protected var nextPoint:Point;

		/**
		 * paints the land and fills in all the visual details - fills, strokes, shading, wall hits.
		 * performs the bitmapping as well.
		 */
		private var painter:OutlinePainter;

		// RLH: conflicts with inherited tileSet
		//private var tileSet:TileSet;

		public function TerrainOutliner( tmap:TileMap, rc:RenderContext ) {

			super( tmap, rc );

			this.tileSet = tmap.tileSet;

			this.curPoint = new Point();
			this.nextPoint = new Point();

			this.painter = new OutlinePainter( rc );

		} //

		override public function render():void {

			this.painter.startPaintBatch();

			this.drawLocal( 0, 0, this.tileMap.rows-1, this.tileMap.cols-1 );

			this.painter.endTerrainPaint();

			this.painter.endPaintBatch();

		} //

		/**
		 * - eraseRect is the rect area that was just erased and must be redrawn.
		 * 
		 * because redrawing one tile might affect nearby tiles as well, the actual area redrawn has to extend
		 * fairly far beyond the tile itself. eraseRect is the area erased which must be filled, and drawing
		 * should extend beyond this area to make sure there are no sharp edges.
		 */
		override public function renderArea( eraseRect:Rectangle ):void {

			var minRow:int = Math.floor( eraseRect.y / this.tileSize ) - 1;
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

			this.painter.startPaintBatch();

			this.drawLocal( minRow, minCol, maxRow, maxCol );

			this.painter.endTerrainPaint();
			this.painter.endPaintBatch();

		}

		/**
		 * render a sub-grid of the tilemap.
		 */
		private function drawLocal( minRow:int, minCol:int, maxRow:int, maxCol:int ):void {

			var tile:LandTile;

			this.tileMap.beginSearch();

			var tiles:Vector.<Vector.<LandTile>> = this.tileMap.getTiles();
			var tileRow:Vector.<LandTile>;

			for( var r:int = minRow; r <= maxRow; r++ ) {

				tileRow = tiles[r];

				for( var c:int = minCol; c <= maxCol; c++ ) {

					//tile = this.tileMap.getTile( r, c );
					tile = tileRow[c];

					if ( tile.type == 0 ) {
						continue;
					} else if ( tile.search_id < this.tileMap.cur_search ) {

						// first time seeing this tile in this search.
						// need to mark the borders as not being drawn, in case they had been drawn in a previous render.
						tile.drawnBorders = 0;
						tile.search_id = this.tileMap.cur_search;

					}
					// this test is no longer accurate - borders are all out-of-whack.
					/*else if ( tile.drawnBorders >= tile.borders ) {
						continue;										// all borders drawn for this search.
					}*/

					// A lot of new, confusing code here. Basically need to find the tiles that have borders.
					if ( !(tile.drawnBorders & LandTile.RIGHT) &&
						( c == maxCol || tileRow[c+1].type == 0 ) ) {
						this.drawBoundedBorder( tile, LandTile.RIGHT, minRow, minCol, maxRow, maxCol );
					}
					if ( !(tile.drawnBorders & LandTile.LEFT) &&
						( c == minCol || tileRow[c-1].type == 0 ) ) {
						this.drawBoundedBorder( tile, LandTile.LEFT, minRow, minCol, maxRow, maxCol );
					}
					if ( !(tile.drawnBorders & LandTile.TOP) &&
						( r == minRow || tiles[r-1][c].type == 0 ) ) {
						this.drawBoundedBorder( tile, LandTile.TOP, minRow, minCol, maxRow, maxCol );
					}
					if ( !(tile.drawnBorders & LandTile.BOTTOM) && 
						( r == maxRow || tiles[r+1][c].type == 0 ) ) {
						this.drawBoundedBorder( tile, LandTile.BOTTOM, minRow, minCol, maxRow, maxCol );
					}

				} // for-column loop.

			} // for-row loop.

		} // drawLocal()

		/**
		 * The border of a region of tiles, bounded within the given row,col limits.
		 */
		private function drawBoundedBorder( startTile:LandTile, startBorder:uint, minRow:int, minCol:int, maxRow:int, maxCol:int ):void {

			var tile:LandTile = startTile;
			var curBorder:uint = startBorder;

			var nextTile:LandTile;
			var nextBorder:uint;

			var nextTileFound:Boolean;

			this.computeBorderStart( tile, curBorder );

			do {

				tile.drawnBorders |= curBorder;
				nextTileFound = false;

				if ( curBorder == LandTile.TOP ) {

					if ( tile.col < maxCol ) {
						if ( tile.row > minRow ) {					// try top-right tile.
	
							nextTile = this.tileMap.getTile( tile.row-1, tile.col+1 );
							if ( nextTile.type != 0 ) {
								nextBorder = LandTile.LEFT;
								this.getLeftPoint( nextTile, this.nextPoint );
								nextTileFound = true;
							}
	
						}
						if ( !nextTileFound ) {					// try tile to the right.
							nextTile = this.tileMap.getTile( tile.row, tile.col+1 );
							if ( nextTile.type != 0 ) {
								nextBorder = LandTile.TOP;
								this.getTopPoint( nextTile, this.nextPoint );
								nextTileFound = true;
							}
						}
					}
					if ( !nextTileFound ) {
						nextTile = tile;
						nextBorder = LandTile.RIGHT;
						this.getRightPoint( nextTile, this.nextPoint );
					}
					
				} else if ( curBorder == LandTile.RIGHT ) {

					if ( tile.row < maxRow ) {
						if ( tile.col < maxCol ) {
	
							nextTile = this.tileMap.getTile( tile.row+1, tile.col+1 );
							if ( nextTile.type != 0 ) {
								nextBorder = LandTile.TOP;
								this.getTopPoint( nextTile, this.nextPoint );
								nextTileFound = true;
							}
	
						}
						if ( !nextTileFound ) {
							nextTile = this.tileMap.getTile( tile.row+1, tile.col );
							if ( nextTile.type != 0 ) {
								nextBorder = LandTile.RIGHT;
								this.getRightPoint( nextTile, this.nextPoint );
								nextTileFound = true;
							}
						}
					}
					if ( !nextTileFound ) {
						nextTile = tile;
						nextBorder = LandTile.BOTTOM;
						this.getBottomPoint( nextTile, this.nextPoint );
					}

				} else if ( curBorder == LandTile.BOTTOM ) {

					if ( tile.col > minCol ) {
						if ( tile.row < maxRow ) {

							nextTile = this.tileMap.getTile( tile.row+1, tile.col-1 );
							if ( nextTile.type != 0 ) {
								nextBorder = LandTile.RIGHT;
								this.getRightPoint( nextTile, this.nextPoint );
								nextTileFound = true;
							}

						}
						if ( !nextTileFound ) {
							nextTile = this.tileMap.getTile( tile.row, tile.col-1 );
							if ( nextTile.type != 0  ) {
								nextBorder = LandTile.BOTTOM;
								this.getBottomPoint( nextTile, this.nextPoint );
								nextTileFound = true;
							}
						}
					}
					if ( !nextTileFound ) {
						nextTile = tile;
						nextBorder = LandTile.LEFT;
						this.getLeftPoint( nextTile, this.nextPoint );
					}
					
				} else {

					if ( tile.row > minRow ) {
						if ( tile.col > minCol ) {
	
							nextTile = this.tileMap.getTile( tile.row-1, tile.col-1 );
							if ( nextTile.type != 0 ) {
								nextBorder = LandTile.BOTTOM;
								this.getBottomPoint( nextTile, this.nextPoint );
								nextTileFound = true;
							}
	
						}
						if ( !nextTileFound) {
							nextTile = this.tileMap.getTile( tile.row-1, tile.col );
							if ( nextTile.type != 0 ) {
								nextBorder = LandTile.LEFT;
								this.getLeftPoint( nextTile, this.nextPoint );
								nextTileFound = true;
							}
						}
					}
					if ( !nextTileFound ) {
						nextTile = tile;
						nextBorder = LandTile.TOP;
						this.getTopPoint( nextTile, this.nextPoint );
					}
					
				} // end-if.

				// only used as a step to tell the painter the combined borders being drawn.
				// this value will get overridden with just the nextBorder.
				curBorder = curBorder | nextBorder;

				this.painter.curveStroke( this.curPoint,
					( this.nextPoint.x + this.curPoint.x )/ 2,
					( this.nextPoint.y + this.curPoint.y ) / 2,
					curBorder, this.tileSet.getTypeByCode( tile.type ) );

				this.curPoint.x = this.nextPoint.x;
				this.curPoint.y = this.nextPoint.y;

				tile = nextTile;
				curBorder = nextBorder;

				if ( tile.search_id < this.tileMap.cur_search ) {
					tile.search_id = this.tileMap.cur_search;
					tile.drawnBorders = 0;
				}

			} while ( (tile != startTile) || (curBorder != startBorder) );

		} //

		/**
		 * Annoying function to find the correct point at which to start drawing a border.
		 * If you just use an edge point on the current tile the line draw bulges out
		 * at the start of the drawing.
		 * 
		 * Instead you need to find the previous tile that would have led to the the starting tile,
		 * and set your start point as the anchor point between them. Unlike the rest of the code,
		 * the search here proceeds counter-clockwise from the current tile instead of clockwise.
		 * All the checks are reversed and nextPoint is actually the previous point.
		 */
		private function computeBorderStart( tile:LandTile, curBorder:uint ):void {

			var nextTile:LandTile;
			var nextBorder:uint;

			if ( curBorder & LandTile.TOP ) {
				this.getTopPoint( tile, this.curPoint );
			} else if ( curBorder & LandTile.RIGHT ) {
				this.getRightPoint( tile, this.curPoint );
			} else if (curBorder & LandTile.BOTTOM ) {
				this.getBottomPoint( tile, this.curPoint );
			} else {
				this.getLeftPoint( tile, this.curPoint );
			}

			if ( curBorder == LandTile.TOP ) {

				nextTile = this.tileMap.getTile( tile.row-1, tile.col-1 );
				if ( nextTile != null && nextTile.type != 0 ) {

					nextBorder = LandTile.RIGHT;
					this.getRightPoint( nextTile, this.nextPoint );

				} else {
					
					nextTile = this.tileMap.getTile( tile.row, tile.col-1 );
					if ( nextTile != null && nextTile.type != 0 ) {
						
						nextBorder = LandTile.TOP;
						this.getTopPoint( nextTile, this.nextPoint );

					} else {

						nextTile = tile;
						nextBorder = LandTile.LEFT;
						this.getLeftPoint( nextTile, this.nextPoint );
						
					} //

				} //
				
			} else if ( curBorder == LandTile.RIGHT ) {
				
				nextTile = this.tileMap.getTile( tile.row-1, tile.col+1 );
				if ( nextTile != null && nextTile.type != 0 ) {

					nextBorder = LandTile.BOTTOM;
					this.getBottomPoint( nextTile, this.nextPoint );

				} else {

					nextTile = this.tileMap.getTile( tile.row-1, tile.col );
					if ( nextTile != null && nextTile.type != 0 ) {
						
						nextBorder = LandTile.RIGHT;
						this.getRightPoint( nextTile, this.nextPoint );
						
					} else {
						
						nextTile = tile;
						nextBorder = LandTile.TOP;
						this.getTopPoint( nextTile, this.nextPoint );
						
					} //
					
				} //
				
			} else if ( curBorder == LandTile.BOTTOM ) {
				
				nextTile = this.tileMap.getTile( tile.row+1, tile.col+1 );
				if ( nextTile != null && nextTile.type != 0 ) {

					nextBorder = LandTile.LEFT;
					this.getLeftPoint( nextTile, this.nextPoint );
					
				} else {

					nextTile = this.tileMap.getTile( tile.row, tile.col+1 );
					if ( nextTile != null && nextTile.type != 0 ) {
						
						nextBorder = LandTile.BOTTOM;
						this.getBottomPoint( nextTile, this.nextPoint );
						
					} else {

						nextTile = tile;
						nextBorder = LandTile.RIGHT;
						this.getRightPoint( nextTile, this.nextPoint );

					} //
					
				} //
				
			} else {
				
				nextTile = this.tileMap.getTile( tile.row+1, tile.col-1 );
				if ( nextTile != null && nextTile.type != 0 ) {
					
					nextBorder = LandTile.TOP;
					this.getTopPoint( nextTile, this.nextPoint );
					
				} else {

					nextTile = this.tileMap.getTile( tile.row+1, tile.col );
					if ( nextTile != null && nextTile.type != 0 ) {
						
						nextBorder = LandTile.LEFT;
						this.getLeftPoint( nextTile, this.nextPoint );

					} else {

						// wrap around the current tile.
						nextTile = tile;
						nextBorder = LandTile.BOTTOM;
						this.getBottomPoint( nextTile, this.nextPoint );

					} //

				} //

			} // end-if.

			this.painter.startStroke( ( this.nextPoint.x + this.curPoint.x )/ 2,
				( this.nextPoint.y + this.curPoint.y ) / 2 );

		} //

		private function getTopPoint( tile:LandTile, p:Point ):void {

			p.x = ( tile.col + 0.5 )*this.tileSize + tile.tileDataX;
			p.y = tile.row*this.tileSize + tile.tileDataY;

		} //

		private function getRightPoint( tile:LandTile, p:Point ):void {

			p.x = ( tile.col + 1 )*this.tileSize + tile.tileDataX;
			p.y = ( tile.row + 0.5 )*this.tileSize + tile.tileDataY;

		} //

		private function getBottomPoint( tile:LandTile, p:Point ):void {

			p.x = ( tile.col + 0.5 )*this.tileSize + tile.tileDataX;
			p.y = ( tile.row + 1 )*this.tileSize + tile.tileDataY;

		} //

		private function getLeftPoint( tile:LandTile, p:Point ):void {

			p.x = ( tile.col )*this.tileSize + tile.tileDataX;
			p.y = ( tile.row + 0.5 )*this.tileSize + tile.tileDataY;

		} //

		private function getDrawPoint( tile:LandTile, side:uint, p:Point ):void {

			if ( side == LandTile.TOP ) {

				p.x = ( tile.col + 0.5 )*this.tileSize;
				p.y = tile.row*this.tileSize;

			} else if ( side == LandTile.RIGHT ) {

				p.x = ( tile.col + 1 )*this.tileSize;
				p.y = ( tile.row + 0.5 )*this.tileSize;

			} else if ( side == LandTile.BOTTOM ) {

				p.x = ( tile.col + 0.5 )*this.tileSize;
				p.y = ( tile.row + 1 )*this.tileSize;

			} else {

				// LEFT
				p.x = ( tile.col )*this.tileSize;
				p.y = ( tile.row + 0.5 )*this.tileSize;

			} //

		} //

		public function set strokeSize( s:Number ):void {
			this.painter.strokeSize = s;
		}

		override public function setRenderContext( rc:RenderContext ):void {

			this.painter.setRenderContext( rc );

		} //

		public function getPainter():OutlinePainter {
			return this.painter;
		}

		public function setPainter( p:OutlinePainter ):void {
			this.painter = p;
		}

	} // End class

} // End package