package game.scenes.lands.shared.tileLib.renderers {

	/**
	 * 
	 * Tree renderer is a lot like the terrain renderer with a few differences.
	 * 
	 * First, lower tiles aren't drawn below all higher tiles in draw order.
	 * Secondly, the exact points chosen on the draw line might end up being different???
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

	public class TreeRenderer extends MapRenderer {

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

		private var tileTypes:Vector.<TileType>;
		private var curType:uint;

		public var sortDetails:Boolean = false;

		/**
		 * OR's all the tile type codes active in the redraw area, so tile types with non-matching codes can be skipped.
		 */
		private var areaTiles:uint;

		public function TreeRenderer( tmap:TileMap, rc:RenderContext, randMap:RandomMap ) {

			super( tmap, rc );

			this.tileTypes = this.tileSet.tileTypes;

			this.curPoint = new Point();
			this.nextPoint = new Point();

			this.painter = new TerrainPainter( tmap.drawHits, rc, randMap );
			this.painter.sortDetails = this.sortDetails;

		} //

		override public function render():void {

			this.painter.startPaintBatch();

			var terrain:TerrainTileType;

			//var t1:Number = getTimer();

			this.areaTiles = 0xFFFFFFFF;

			for( var i:int = this.tileTypes.length-1; i >= 0; i-- ) {

				terrain = this.tileTypes[ i ] as TerrainTileType;
				if ( terrain == null || (this.areaTiles & terrain.type) == 0 ) {
					continue;
				}

				this.curType = terrain.type;

				this.painter.startPaintType( terrain );

				this.areaTiles = 0;
				this.drawLocal( 0, 0, this.tileMap.rows-1, this.tileMap.cols-1 );
				this.painter.endPaintType();

				if ( this.areaTiles == 0 ) {
					// absolutely nothing left to render.
					break;
				}

			} // for-loop.

			//var t2:Number = getTimer();
			//trace( "TREE RENDER TIME: " + (t2-t1) );

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

			this.areaTiles = 0xFFFFFFFF;

			for( var i:int = this.tileTypes.length-1; i >= 0; i-- ) {

				terrain = this.tileTypes[ i ] as TerrainTileType;
				if ( terrain == null ) {
					continue;
				}

				if ( (this.areaTiles & terrain.type) == 0 ) {

					continue;
				}

				this.curType = terrain.type;

				this.painter.startPaintType( terrain );

				this.areaTiles = 0;
				this.drawLocal( minRow, minCol, maxRow, maxCol );
				this.painter.endPaintType();

				if ( this.areaTiles == 0 ) {
					// absolutely nothing left to render.
					break;
				}

			} //

			this.painter.endPaintBatch();

		} //

		/**
		 * draw a range of tiles.
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
					} else if ( !(tile.type & this.curType) ) {

						this.areaTiles |= tile.type;		// mark any other tile types that have to be checked.
						continue;

					} else if ( tile.search_id < this.tileMap.cur_search ) {

						// first time seeing this tile in this search.
						// need to mark the borders as not being drawn, in case they had been drawn in a previous render.
						this.areaTiles |= tile.type;
						tile.drawnBorders = 0;
						tile.search_id = this.tileMap.cur_search;

					}

					if ( !(tile.drawnBorders & LandTile.RIGHT) &&
						( c == maxCol || !(tileRow[c+1].type & this.curType) ) ) {
						this.drawBorder( tile, LandTile.RIGHT, minRow, minCol, maxRow, maxCol );
					}
					if ( !(tile.drawnBorders & LandTile.LEFT) &&
						( c == minCol || !(tileRow[c-1].type & this.curType) ) ) {
						this.drawBorder( tile, LandTile.LEFT, minRow, minCol, maxRow, maxCol );
					}
					if ( !(tile.drawnBorders & LandTile.TOP) &&
						( r == minRow || !(tiles[r-1][c].type & this.curType) ) ) {
						this.drawBorder( tile, LandTile.TOP, minRow, minCol, maxRow, maxCol );
					}
					if ( !(tile.drawnBorders & LandTile.BOTTOM) && 
						( r == maxRow || !(tiles[r+1][c].type & this.curType) ) ) {
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

					if ( tile.row > minRow && tile.col < maxCol ) {					// try top-right tile.

						nextTile = this.tileMap.getTile( tile.row-1, tile.col+1 );
						if ( nextTile.type & this.curType ) {
							nextBorder = LandTile.LEFT;
							this.getLeftPoint( nextTile, this.nextPoint );
							nextTileFound = true;
						}

					}
					if ( !nextTileFound && tile.col < maxCol ) {					// try tile to the right.
						nextTile = this.tileMap.getTile( tile.row, tile.col+1 );
						if ( nextTile.type & this.curType ) {
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

					if ( tile.row < maxRow && tile.col < maxCol ) {

						nextTile = this.tileMap.getTile( tile.row+1, tile.col+1 );
						if ( nextTile.type & this.curType ) {
							nextBorder = LandTile.TOP;
							this.getTopPoint( nextTile, this.nextPoint );
							nextTileFound = true;
						}

					}
					if ( !nextTileFound && tile.row < maxRow ) {
						nextTile = this.tileMap.getTile( tile.row+1, tile.col );
						if ( nextTile.type & this.curType ) {
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
					
					if ( tile.row < maxRow && tile.col > minCol ) {
						
						nextTile = this.tileMap.getTile( tile.row+1, tile.col-1 );
						if ( nextTile.type & this.curType ) {
							nextBorder = LandTile.RIGHT;
							this.getRightPoint( nextTile, this.nextPoint );
							nextTileFound = true;
						}
						
					}
					if ( !nextTileFound && tile.col > minCol ) {
						nextTile = this.tileMap.getTile( tile.row, tile.col-1 );
						if ( nextTile.type & this.curType  ) {
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

					if ( tile.row > minRow && tile.col > minCol ) {

						nextTile = this.tileMap.getTile( tile.row-1, tile.col-1 );
						if ( nextTile.type & this.curType ) {
							nextBorder = LandTile.BOTTOM;
							this.getBottomPoint( nextTile, this.nextPoint );
							nextTileFound = true;
						}
						
					}
					if ( !nextTileFound && tile.row > minRow ) {
						nextTile = this.tileMap.getTile( tile.row-1, tile.col );
						if ( nextTile.type & this.curType ) {
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

				this.renderContext.curTile = tile;

				this.painter.curveStroke( this.curPoint,
					( this.nextPoint.x + this.curPoint.x )/ 2,
					( this.nextPoint.y + this.curPoint.y ) / 2,
					curBorder | nextBorder,
						( tile.row==maxRow ) ||
						( tile.row == minRow && minRow != 0 ) ||
						( tile.col == minCol && minCol != 0 ) ||
						( tile.col == maxCol  ) );

				this.curPoint.x = this.nextPoint.x;
				this.curPoint.y = this.nextPoint.y;

				tile = nextTile;
				curBorder = nextBorder;

				if ( tile.search_id < this.tileMap.cur_search ) {
					this.areaTiles |= tile.type;
					tile.search_id = this.tileMap.cur_search;
					tile.drawnBorders = 0;
				}

			} while ( (tile != startTile) || (curBorder != startBorder) );

		} //

		/**
		 * Annoying function to find the correct point at which to start drawing a border.
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
				if ( nextTile != null && (nextTile.type & this.curType) ) {

					nextBorder = LandTile.RIGHT;
					this.getRightPoint( nextTile, this.nextPoint );

				} else {
					
					nextTile = this.tileMap.getTile( tile.row, tile.col-1 );
					if ( nextTile != null && (nextTile.type & this.curType) ) {
						
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
				if ( nextTile != null && (nextTile.type & this.curType) ) {
					
					nextBorder = LandTile.BOTTOM;
					this.getBottomPoint( nextTile, this.nextPoint );

				} else {

					nextTile = this.tileMap.getTile( tile.row-1, tile.col );
					if ( nextTile != null && (nextTile.type & this.curType) ) {
						
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
				if ( nextTile != null && (nextTile.type & this.curType) ) {

					nextBorder = LandTile.LEFT;
					this.getLeftPoint( nextTile, this.nextPoint );
					
				} else {

					nextTile = this.tileMap.getTile( tile.row, tile.col+1 );
					if ( nextTile != null && (nextTile.type & this.curType) ) {
						
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
				if ( nextTile != null && (nextTile.type & this.curType) ) {
					
					nextBorder = LandTile.TOP;
					this.getTopPoint( nextTile, this.nextPoint );
					
				} else {

					nextTile = this.tileMap.getTile( tile.row+1, tile.col );
					if ( nextTile != null && nextTile.type == this.curType ) {
						
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

		/*private function getNextPoint( tile:LandTile, p:Point, dx:int, dy:int ):void {

			this.curX += dx;
			this.curY += dy;
			p.x = this.curX + dx + tile.jiggleX;
			p.y = this.curY + dy + tile.jiggleY;
			
		} //*/

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