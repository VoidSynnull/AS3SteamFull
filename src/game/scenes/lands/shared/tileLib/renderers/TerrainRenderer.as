package game.scenes.lands.shared.tileLib.renderers {

	/**
	 * Renders 'terrain'-type tile sets.
	 * 
	 * The renderer itself only computes the points where drawing occurs,
	 * while the TerrainPainter paints the strokes themselves.
	 *
	 */

	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.getTimer;
	
	import game.scenes.lands.shared.tileLib.LandTile;
	import game.scenes.lands.shared.tileLib.TileMap;
	import game.scenes.lands.shared.tileLib.classes.RandomMap;
	import game.scenes.lands.shared.tileLib.painters.RenderContext;
	import game.scenes.lands.shared.tileLib.painters.TerrainPainter;
	import game.scenes.lands.shared.tileLib.tileTypes.TerrainTileType;
	import game.scenes.lands.shared.tileLib.tileTypes.TileType;

	public class TerrainRenderer extends MapRenderer {

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
		private var painter:TerrainPainter;

		private var terrainTypes:Vector.<TileType>;

		private var curTerrainType:TerrainTileType;

		private var curTypeCode:uint;
		private var curDrawOrder:int;

		public function TerrainRenderer( tmap:TileMap, rc:RenderContext, randMap:RandomMap ) {

			super( tmap, rc );

			this.terrainTypes = this.tileSet.tileTypes;

			this.curPoint = new Point();
			this.nextPoint = new Point();

			this.painter = new TerrainPainter( tmap.drawHits, rc, randMap );

		} //

		override public function render():void {

			this.painter.startPaintBatch();

			var terrain:TerrainTileType;

			//var t1:Number = getTimer();

			for( var i:int = this.terrainTypes.length-1; i >= 0; i-- ) {

				terrain = this.terrainTypes[ i ] as TerrainTileType;

				this.curTerrainType = terrain;
				this.curTypeCode = terrain.type;
				this.curDrawOrder = terrain.drawOrder;
	
				this.painter.startPaintType( terrain );

				this.drawLocal( 0, 0, this.tileMap.rows-1, this.tileMap.cols-1 );

				this.painter.endPaintType();

			} // for-loop.

			//var t2:Number = getTimer();
			//trace( "TERRAIN RENDER TIME: " + (t2-t1) );

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

			this.painter.startPaintBatch();

			var terrain:TerrainTileType;

			var minRow:int = Math.floor( eraseRect.y / this.tileSize ) - 2;
			var maxRow:int = Math.ceil( eraseRect.bottom / this.tileSize )+1;
			var minCol:int = Math.floor( eraseRect.x / this.tileSize )-2;
			var maxCol:int = Math.ceil( eraseRect.right / this.tileSize )+1;

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

			for( var i:int = this.terrainTypes.length-1; i >= 0; i-- ) {

				terrain = this.terrainTypes[ i ] as TerrainTileType;

				this.curTerrainType = terrain;
				this.curTypeCode = terrain.type;
				this.curDrawOrder = terrain.drawOrder;

				this.painter.startPaintType( terrain );

				this.drawLocal( minRow, minCol, maxRow, maxCol );

				this.painter.endPaintType();

			} //

			this.painter.endPaintBatch();

		} //

		/**
		 * far more efficient method of updating a tile that has been changed by only drawing
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

					if ( !this.renderable( tile ) ) {
						continue;
					} else if ( tile.search_id < this.tileMap.cur_search ) {

						// first time seeing this tile in this search.
						// need to mark the borders as not being drawn, in case they had been drawn in a previous render.
						tile.drawnBorders = 0;
						tile.search_id = this.tileMap.cur_search;

					}

					// A lot of new, confusing code here. Basically need to find the tiles that have borders.
					if ( !(tile.drawnBorders & LandTile.RIGHT) &&
						( c == maxCol || !this.renderable( tileRow[c+1] )) ) {
						this.drawBorder( tile, LandTile.RIGHT, minRow, minCol, maxRow, maxCol );
					}
					if ( !(tile.drawnBorders & LandTile.LEFT) &&
						( c == minCol || !this.renderable( tileRow[c-1] )) ) {
						this.drawBorder( tile, LandTile.LEFT, minRow, minCol, maxRow, maxCol );
					}
					if ( !(tile.drawnBorders & LandTile.TOP) &&
						( r == minRow || !this.renderable( tiles[r-1][c] ) ) ) {
						this.drawBorder( tile, LandTile.TOP, minRow, minCol, maxRow, maxCol );
					}
					if ( !(tile.drawnBorders & LandTile.BOTTOM) && 
						( r == maxRow || !this.renderable( tiles[r+1][c] ) ) ) {
						this.drawBorder( tile, LandTile.BOTTOM, minRow, minCol, maxRow, maxCol );
					}

				} // for-column loop.

			} // for-row loop.

		} // drawLocal()

		/**
		 * The border of a region of tiles, bounded within the given row,col limits.
		 */
		private function drawBorder( startTile:LandTile, startBorder:uint, minRow:int, minCol:int, maxRow:int, maxCol:int ):void {

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
	
							if ( (nextTile = this.getIfRenderable( tile.row-1, tile.col+1 )) != null ) {
								nextBorder = LandTile.LEFT;
								this.getLeftPoint( nextTile, this.nextPoint );
								nextTileFound = true;
							}

						}
						// try tile to the right.
						if ( !nextTileFound && (nextTile = this.getIfRenderable( tile.row, tile.col+1 )) != null ) {

							nextBorder = LandTile.TOP;
							this.getTopPoint( nextTile, this.nextPoint );
							nextTileFound = true;

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
	
							if ( (nextTile = this.getIfRenderable( tile.row+1, tile.col+1 )) != null ) {
								nextBorder = LandTile.TOP;
								this.getTopPoint( nextTile, this.nextPoint );
								nextTileFound = true;
							}
	
						}
						if ( !nextTileFound && (nextTile = this.getIfRenderable( tile.row+1, tile.col )) != null ) {
	
							nextBorder = LandTile.RIGHT;
							this.getRightPoint( nextTile, this.nextPoint );
							nextTileFound = true;
	
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
							
							if ( (nextTile = this.getIfRenderable( tile.row+1, tile.col-1 )) != null ) {
								nextBorder = LandTile.RIGHT;
								this.getRightPoint( nextTile, this.nextPoint );
								nextTileFound = true;
							}
							
						}
						if ( !nextTileFound && (nextTile = this.getIfRenderable( tile.row, tile.col-1 )) != null ) {
	
							nextBorder = LandTile.BOTTOM;
							this.getBottomPoint( nextTile, this.nextPoint );
							nextTileFound = true;

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

							if ( (nextTile = this.getIfRenderable( tile.row-1, tile.col-1 )) != null ) {
								nextBorder = LandTile.BOTTOM;
								this.getBottomPoint( nextTile, this.nextPoint );
								nextTileFound = true;
							}

						}
						if ( !nextTileFound && (nextTile = this.getIfRenderable( tile.row-1, tile.col )) != null ) {

							nextBorder = LandTile.LEFT;
							this.getLeftPoint( nextTile, this.nextPoint );
							nextTileFound = true;

						}
					}
					if ( !nextTileFound ) {
						nextTile = tile;
						nextBorder = LandTile.TOP;
						this.getTopPoint( nextTile, this.nextPoint );
					}

				} // end-if.

				this.painter.curveStroke( this.curPoint,
					( this.nextPoint.x + this.curPoint.x )/ 2,
					( this.nextPoint.y + this.curPoint.y ) / 2,
					curBorder | nextBorder,
						( tile.row == maxRow ) ||
						( tile.row == minRow && minRow != 0 ) ||
						( tile.col == minCol && minCol != 0 ) ||
						( tile.col == maxCol  ) );

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
		 * checks if tile at row, col is renderable during the current render pass.
		 */
		[inline]
		final protected function getIfRenderable( row:int, col:int ):LandTile {

			var tile:LandTile = this.tileMap.getTile( row, col );

			// anything with a lower draw order was already drawn.
			if ( tile.type == 0 || (this.tileSet.getTypeByCode(tile.type).drawOrder < this.curDrawOrder) ) {
				return null;
			}

			return tile;

		} //

		/*public function renderableType( type:TileType ):Boolean {

			if ( type == null || type.drawOrder < this.curDrawOrder ) {
				return false;
			}
			
			return true;

		} //*/

		[inline]
		final override public function renderable( tile:LandTile ):Boolean {

			var type:TileType = this.tileSet.getTypeByCode( tile.type );
			if ( type == null || type.drawOrder < this.curDrawOrder ) {
				return false;
			}

			return true;

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

				if ( tile.row > 0 && tile.col > 0 && (nextTile = this.getIfRenderable(tile.row-1, tile.col-1)) != null ) {

					nextBorder = LandTile.RIGHT;
					this.getRightPoint( nextTile, this.nextPoint );

				} else {
					
					if ( tile.col > 0 && (nextTile = this.getIfRenderable( tile.row, tile.col-1 )) != null ) {
						
						nextBorder = LandTile.TOP;
						this.getTopPoint( nextTile, this.nextPoint );

					} else {

						nextTile = tile;
						nextBorder = LandTile.LEFT;
						this.getLeftPoint( nextTile, this.nextPoint );
						
					} //

				} //
				
			} else if ( curBorder == LandTile.RIGHT ) {
				
				if ( tile.row > 0 && tile.col < this.tileMap.cols-1 && (nextTile = this.getIfRenderable(tile.row-1, tile.col+1)) != null ) {
					
					nextBorder = LandTile.BOTTOM;
					this.getBottomPoint( nextTile, this.nextPoint );

				} else {

					if ( tile.row > 0 && (nextTile = this.getIfRenderable( tile.row-1, tile.col )) != null ) {
						
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
				if ( tile.row < this.tileMap.rows-1 && tile.col < this.tileMap.cols-1
					&& (nextTile = this.getIfRenderable(tile.row+1, tile.col+1)) != null ) {

					nextBorder = LandTile.LEFT;
					this.getLeftPoint( nextTile, this.nextPoint );
					
				} else {

					if ( tile.col < this.tileMap.cols-1 && (nextTile = this.getIfRenderable( tile.row, tile.col+1 )) != null ) {
						
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
				if ( tile.row < this.tileMap.rows-1 && tile.col > 0 && (nextTile = this.getIfRenderable(tile.row+1, tile.col-1)) != null ) {

					nextBorder = LandTile.TOP;
					this.getTopPoint( nextTile, this.nextPoint );

				} else {

					if ( tile.row < this.tileMap.rows-1 && (nextTile = this.getIfRenderable( tile.row+1, tile.col )) != null ) {
						
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

		// replaced by individual more efficient functions.
		/*private function getDrawPoint( tile:LandTile, side:uint, p:Point ):void {

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

		} //*/

		override public function setRenderContext( context:RenderContext ):void {

			super.setRenderContext( context );
			this.painter.setRenderContext( context );

		} //

		public function set drawOutlines( b:Boolean ):void {
			this.painter.drawOutlines = b;
		} //

		public function getPainter():TerrainPainter {
			return this.painter;
		}

		public function setPainter( p:TerrainPainter ):void {
			this.painter = p;
		}

	} // End class

} // End package