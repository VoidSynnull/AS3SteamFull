package game.scenes.lands.shared.tileLib.renderers {
	
	/**
	 * Differences from the TerrainRenderer:
	 * 
	 *  - the terrain renderer draws curved outlines, this renderer draws mostly straight edges.
	 *  - the terrain renderer allows multiple types for a single tile (using bitwise OR), this uses only one type per tile.
	 */

	import flash.display.BitmapData;
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.getTimer;
	
	import game.scenes.lands.shared.tileLib.LandTile;
	import game.scenes.lands.shared.tileLib.TileMap;
	import game.scenes.lands.shared.tileLib.painters.RenderContext;
	import game.scenes.lands.shared.tileLib.tileTypes.TileType;

	public class BuildingRenderer extends MapRenderer {

		/**
		 * eventually might want to add a special painter that does the actual painting - especially as you start to add
		 * building features like lights, windows, doors, roofs.
		 * 
		 */

		private var tileTypes:Vector.<TileType>;
		private var curTileCode:uint;
		private var curTileType:TileType;

		// used to track points for drawing.
		private var curPoint:Point;
		private var nextPoint:Point;

		private var drawHits:Boolean;

		//private var viewBitmap:BitmapData;
		//private var hitBitmap:BitmapData;

		/**
		 * sprites used for drawing before copying over to the destination bitmaps.
		 */
		private var viewPane:Shape;
		private var hitPane:Shape;

		// graphics for the draw sprites.
		private var viewGraphics:Graphics;
		private var hitGraphics:Graphics;

		private var nextTileType:TileType;
		private var curTypeIndex:int;
		private var nextTypeIndex:int;

		public function BuildingRenderer( tmap:TileMap, rc:RenderContext ) {

			super( tmap );

			this.drawHits = tmap.drawHits && rc.drawHits;

			this.tileTypes = this.tileSet.tileTypes;

			// stuff used for drawing.
			this.curPoint = new Point();
			this.nextPoint = new Point();

			this.setRenderContext( rc );

		} //

		/**
		 * 
		 * temporary function till I figure a better way to do this.
		 * Render the data from a template using the given view. The tileSet, tileSize data doesn't change.
		 * 
		 */
		override public function prepareTemplate( templateMap:TileMap, templateView:BitmapData ):void {

			this.tileMap = templateMap;
			this.drawHits = false;

		} //

		override public function render():void {

			this.beginRender();

			//var t1:Number = getTimer();

			//for( var i:int = this.tileTypes.length-1; i >= 0; i-- ) {
			//this.beginTileType( this.tileTypes[ this.tileTypes.length-1 ] );

			this.nextTypeIndex = this.tileTypes.length-1;

			do {

				this.beginTileType( this.nextTypeIndex );

				this.nextTypeIndex = -1;

				this.drawLocal( 0, 0, this.tileMap.rows-1, this.tileMap.cols-1 );
				this.endTileType();

			} while ( nextTypeIndex >= 0 );

			//var t2:Number = getTimer();
			//trace( "BUILDING RENDER TIME: " + (t2-t1) );

			this.copyToBitmaps();

		} //

		private function updateTypeIndex( type:uint ):void {

			for( var i:int = this.nextTypeIndex+1; i < this.curTypeIndex; i++ ) {

				if ( this.tileTypes[i].type == type ) {
					this.nextTypeIndex = i;
				} //

			} //

		} //

		/**
		 * - eraseRect is the rect area that was just erased and must be redrawn.
		 * 
		 * because redrawing one tile might affect nearby tiles as well, the actual area redrawn has to extend
		 * beyond the tile itself. eraseRect is the area erased which must be filled, and drawing
		 * should extend beyond this area to make sure there are no sharp edges.
		 */
		override public function renderArea( eraseRect:Rectangle ):void {

			this.beginRender();

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

			//var t1:Number = getTimer();

			this.nextTypeIndex = this.tileTypes.length-1;
			
			do {
				
				this.beginTileType( this.nextTypeIndex );
				this.nextTypeIndex = -1;

				this.drawLocal( minRow, minCol, maxRow, maxCol );
				this.endTileType();
				
			} while ( nextTypeIndex >= 0 );

			/*for( var i:int = this.tileTypes.length-1; i >= 0; i-- ) {
				this.beginTileType( this.tileTypes[i] );
				this.drawLocal( minRow, minCol, maxRow, maxCol );
				this.endTileType();
			} //*/

			//var t2:Number = getTimer();
			//trace( "BUILDING AREA RENDER TIME: " + (t2-t1) );

			this.copyToBitmaps();

		}

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
					}
					else if ( tile.type != this.curTileCode ) {

						this.updateTypeIndex( tile.type );
						continue;

					} else if ( tile.search_id < this.tileMap.cur_search ) {

						// first time seeing this tile in this search.
						// need to mark the borders as not being drawn, in case they had been drawn in a previous render.
						tile.drawnBorders = 0;
						tile.search_id = this.tileMap.cur_search;

					}

					// A lot of new, confusing code here. Basically need to find the tiles that have borders.
					if ( !(tile.drawnBorders & LandTile.TOP) &&
						( r == minRow || (tiles[r-1][c].type != this.curTileCode) ) ) {
						this.drawBorder( tile, LandTile.TOP, minRow, minCol, maxRow, maxCol );
					}
					if ( !(tile.drawnBorders & LandTile.RIGHT) &&
						( c == maxCol || (tileRow[c+1].type != this.curTileCode)) ) {
						this.drawBorder( tile, LandTile.RIGHT, minRow, minCol, maxRow, maxCol );
					}
					if ( !(tile.drawnBorders & LandTile.BOTTOM) && 
						( r == maxRow || (tiles[r+1][c].type != this.curTileCode) ) ) {
						this.drawBorder( tile, LandTile.BOTTOM, minRow, minCol, maxRow, maxCol );
					}
					if ( !(tile.drawnBorders & LandTile.LEFT) &&
						( c == minCol || (tileRow[c-1].type != this.curTileCode) ) ) {
						this.drawBorder( tile, LandTile.LEFT, minRow, minCol, maxRow, maxCol );
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

			do {

				tile.drawnBorders |= curBorder;
				nextTileFound = false;

				if ( curBorder == LandTile.TOP ) {

					this.getTopRight( tile, this.nextPoint );

					if ( tile.col < maxCol ) {

						if ( tile.row > minRow ) {					// try top-right tile.
	
							nextTile = this.tileMap.getTile( tile.row-1, tile.col+1 );
							if ( nextTile.type == this.curTileCode ) {
	
								nextTileFound = true;
								nextBorder = LandTile.LEFT;
								if ( this.tileMap.canDrawSlope( tile.row-1, tile.col, -1, 1, this.curTileCode ) ) {
	
									this.getTopLeft( nextTile, this.nextPoint );
	
								} //
	
							} //
	
						}
						if ( !nextTileFound ) {					// try tile to the right.
							nextTile = this.tileMap.getTile( tile.row, tile.col+1 );
							if ( nextTile.type == this.curTileCode ) {
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

					if ( tile.row < maxRow ) {
						if ( tile.col < maxCol ) {
	
							nextTile = this.tileMap.getTile( tile.row+1, tile.col+1 );
							if ( nextTile.type == this.curTileCode ) {
	
								// NOTE: this is only here to force a platform edge. maybe just use a bool for draw platform in this whole thing.
								curBorder = LandTile.TOP;
								nextBorder = LandTile.TOP;
								nextTileFound = true;
								if ( this.tileMap.canDrawSlope( tile.row, tile.col+1, 1, 1, this.curTileCode ) ) {
									
									this.getTopRight( nextTile, this.nextPoint );
									
								} //
	
							} //
	
						}
						if ( !nextTileFound ) {
							nextTile = this.tileMap.getTile( tile.row+1, tile.col );
							if ( nextTile.type == this.curTileCode ) {
								nextBorder = LandTile.RIGHT;
								nextTileFound = true;
							}
						}
					}

					if ( !nextTileFound ) {
						nextTile = tile;
						nextBorder = LandTile.BOTTOM;
					}

				} else if ( curBorder == LandTile.BOTTOM ) {

					this.getBottomLeft( tile, this.nextPoint );

					if ( tile.col > minCol ) {
						if ( tile.row < maxRow ) {
							
							nextTile = this.tileMap.getTile( tile.row+1, tile.col-1 );
							if ( nextTile.type == this.curTileCode ) {
	
								nextBorder = LandTile.RIGHT;
								nextTileFound = true;
								if ( this.tileMap.canDrawSlope( tile.row+1, tile.col, 1, -1, this.curTileCode ) ) {
	
									this.getBottomRight( nextTile, this.nextPoint );
									
								} //
	
							}
							
						}
						if ( !nextTileFound ) {
							nextTile = this.tileMap.getTile( tile.row, tile.col-1 );
							if ( nextTile.type == this.curTileCode  ) {
								nextBorder = LandTile.BOTTOM;
								nextTileFound = true;
							}
						}
					}

					if ( !nextTileFound ) {
						nextTile = tile;
						nextBorder = LandTile.LEFT;
					}
					
				} else {

					// LEFT BORDER.
					this.getTopLeft( tile, this.nextPoint );

					if ( tile.row > minRow ) {
						if ( tile.col > minCol ) {
	
							nextTile = this.tileMap.getTile( tile.row-1, tile.col-1 );
							if ( nextTile.type == this.curTileCode ) {
	
								nextBorder = LandTile.BOTTOM;
								nextTileFound = true;
								if ( this.tileMap.canDrawSlope( tile.row, tile.col-1, -1, -1, this.curTileCode ) ) {
	
									this.getBottomLeft( nextTile, this.nextPoint );
									
								} //
	
							}
							
						}
						if ( !nextTileFound ) {
							nextTile = this.tileMap.getTile( tile.row-1, tile.col );
							if ( nextTile.type == this.curTileCode ) {
								nextBorder = LandTile.LEFT;
								nextTileFound = true;
							}
						}
					}

					if ( !nextTileFound ) {
						nextTile = tile;
						nextBorder = LandTile.TOP;
					}

				} // end-if.

				// draw the tile edge. don't need to include the points because they are class-variables.
				// if drawing becomes too complex, create a new type of land painter, like for terrain.
				this.drawTileEdge( curBorder );

				tile = nextTile;
				curBorder = nextBorder;

				if ( tile.search_id < this.tileMap.cur_search ) {
					tile.search_id = this.tileMap.cur_search;
					tile.drawnBorders = 0;
				}

			} while ( (tile != startTile) || (curBorder != startBorder) );

		} //

		protected function drawTileEdge( tileBorder:uint ):void {

			if ( this.drawHits && this.curTileType.drawHits ) {

				if ( !this.curTileType.drawHits ) {

					this.hitGraphics.lineStyle( 0, 0, 0 );

				} else {

					if ( tileBorder == LandTile.TOP ) {
						this.hitGraphics.lineStyle( this.curTileType.hitLineSize, this.curTileType.hitGroundColor );
					} else if ( tileBorder == LandTile.RIGHT || tileBorder == LandTile.LEFT ) {
						this.hitGraphics.lineStyle( this.curTileType.hitLineSize, this.curTileType.hitWallColor );
					} else {
						this.hitGraphics.lineStyle( this.curTileType.hitLineSize, this.curTileType.hitCeilingColor );
					} //

				}

				this.hitGraphics.lineTo( this.nextPoint.x, this.nextPoint.y );

			}
			this.viewGraphics.lineTo( this.nextPoint.x, this.nextPoint.y );

		} //

		/**
		 * begin painting all tiles of a given type.
		 */
		protected function beginTileType( typeIndex:int ):void {

			var type:TileType = this.curTileType = this.tileTypes[ typeIndex ];
			this.curTileCode = type.type;

			this.curTypeIndex = typeIndex;

			this.viewGraphics.beginBitmapFill( type.viewBitmapFill );
			this.viewGraphics.lineStyle( 0, 0, 0 );
			//this.viewGraphics.lineStyle( type.viewLineSize, type.viewLineColor, 0.5 );

			if ( this.drawHits && type.drawHits ) {
				this.hitGraphics.beginFill( type.hitGroundColor );
			}

		} //

		protected function endTileType():void {

			this.viewGraphics.endFill();

			if ( this.drawHits && this.curTileType.drawHits ) {
				this.hitGraphics.endFill();
			}

		} //

		protected function beginRender():void {

			if ( this.drawHits ) {
				this.hitGraphics.clear();
			}
			this.viewGraphics.clear();

		} //

		/**
		 * 
		 * check if this section of the building should use a sloped tile.
		 * 
		 * emptyRow, emptyCol is the space adjacent to the two tiles between which a slope will be drawn.
		 * 
		 * dr,dc is the direction from the previous tile to the next tile.
		 * 
		 */
		private function checkUseSlope( emptyRow:int, emptyCol:int, dr:int, dc:int ):Boolean {

			var r:int = emptyRow + dr;
			// first test that extending the slope in at least one direction will yield a tileType other than the current one.
			// this is jordan's condition for drawing slopes.

			if (r < 0 || r >= this.tileMap.rows ) {
				return true;						// tiles offscreen will be treated as empty/distinct.
			}

			var c:int = emptyCol + dc;
			if ( c < 0 || c >= this.tileMap.cols ) {
				return true;
			} //

			// jordan's condition of the extended slope being different is satisfied. draw a diagonal.
			if ( this.tileMap.getTile( r, c ).type != this.curTileCode ) {
				return true;
			}

			// now test the back diagonal.
			r = emptyRow - dr;

			if (r < 0 || r >= this.tileMap.rows ) {
				return true;						// tiles offscreen will be treated as empty/distinct.
			}

			c = emptyCol - dc;
			if ( c < 0 || c >= this.tileMap.cols ) {
				return true;
			} //

			// jordan's condition of the extended slope being different is satisfied. draw a diagonal.
			if ( this.tileMap.getTile( r, c ).type != this.curTileCode ) {
				return true;
			}

			return false;

		} //

		protected function copyToBitmaps():void {

			this.renderContext.viewBitmap.draw( this.viewPane, this.renderContext.viewMatrix, null,
				null, this.renderContext.viewPaintRect );

			if ( this.drawHits ) {
				this.renderContext.hitBitmap.draw( this.hitPane, this.renderContext.hitMatrix, null,
					null, this.renderContext.hitPaintRect );
			} //

		} //

		protected function beginBorder( tile:LandTile, border:uint, p:Point ):void {

			if ( border == LandTile.TOP ) {

				if ( tile.row > 0 && tile.col > 0 && this.tileMap.getTileType(tile.row-1, tile.col-1) == tile.type && this.tileMap.canDrawSlope( tile.row-1, tile.col, 1, 1, tile.type ) ) {

					this.getTopRight( tile, p );

				} else {

					this.getTopLeft( tile, p );

				} //				
				
			} else if ( border == LandTile.RIGHT ) {

				if ( tile.row > 0 && tile.col < tileMap.cols &&
					this.tileMap.getTileType(tile.row-1, tile.col+1) == tile.type && this.tileMap.canDrawSlope( tile.row, tile.col+1, 1, -1, tile.type ) ) {
					
					this.getBottomRight( tile, p );

				} else {

					this.getTopRight( tile, p );

				}

			} else if ( border == LandTile.BOTTOM ) {

				if ( tile.row < tileMap.rows && tile.col < tileMap.cols &&
					this.tileMap.getTileType(tile.row+1, tile.col+1) == tile.type && this.tileMap.canDrawSlope( tile.row+1, tile.col, -1, -1, tile.type ) ) {

					this.getBottomLeft( tile, p );

				} else {

					this.getBottomRight( tile, p )

				}

			} else {

				//  BORDER LEFT

				if ( tile.row < tileMap.rows && tile.col > 0 &&
					this.tileMap.getTileType(tile.row+1, tile.col-1) == tile.type && this.tileMap.canDrawSlope( tile.row, tile.col-1, -1, 1, tile.type ) ) {
				} else {

					this.getBottomLeft( tile, p );

				}

			} //

			this.viewGraphics.moveTo( p.x, p.y );
			if ( this.drawHits ) {
				this.hitGraphics.moveTo( p.x, p.y );
			}

		} //

		override public function setRenderContext( rc:RenderContext ):void {

			this.renderContext = rc;

			this.viewPane = rc.viewFillPane;
			this.viewGraphics = rc.viewGraphics;

			this.hitPane = rc.hitPane;
			this.hitGraphics = rc.hitGraphics;

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