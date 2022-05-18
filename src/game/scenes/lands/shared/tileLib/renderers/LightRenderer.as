package game.scenes.lands.shared.tileLib.renderers {

	import flash.display.BitmapData;
	import flash.display.Graphics;
	import flash.filters.BlurFilter;
	import flash.geom.Rectangle;
	import flash.utils.getTimer;
	
	import game.scenes.lands.shared.classes.TileBitmapHits;
	import game.scenes.lands.shared.tileLib.LandTile;
	import game.scenes.lands.shared.tileLib.TileMap;
	import game.scenes.lands.shared.tileLib.classes.TileLayer;
	import game.scenes.lands.shared.tileLib.painters.RenderContext;
	import game.scenes.lands.shared.tileLib.tileTypes.TileType;

	/**
	 * 
	 * NOT CURRENTLY a true MapRenderer. Renders tile lighting.
	 * 
	 */

	public class LightRenderer extends MapRenderer {

		/**
		 * bitmap whose pixels hold the overall lightning information for the scene.
		 */
		//private var lightMap:BitmapData;

		/**
		 * changed the lightmap from bitmap to vector because it's easier to add/subtract existing values.
		 * other operations, like clearing, might be slower though.
		 */
		private var lightMap:Vector.< Vector.<int> >;

		private var lightRows:int;
		private var lightCols:int;

		/**
		 * alpha due to time of day/sky.
		 */
		//private var _skyAlpha:int = 0;

		/**
		 * as dark as things can get.
		 */
		//private var _darkAlpha:int = 250;

		/**
		 * tile maps of the layer that casts shadows (foreground)
		 */
		private var layerMaps:Vector.<TileMap>

		private var layer:TileLayer;

		/**
		 * light values less than this will not propagate.
		 */
		private var minLightStrength:int = 40;

		/**
		 * decay of a light source propagating in clear air. ( subtracted from current value )
		 */
		private var lightAirDecay:int = 60;

		/**
		 * decay of light source hitting a solid.  ( subtracted from current value )
		 */
		private var lightSolidDecay:int = 100;

		private var tileHits:TileBitmapHits;

		private var blurFilter:Array = [ new BlurFilter( 64, 64, 1 ) ];

		public function LightRenderer( layer:TileLayer, tileHitMap:TileBitmapHits ) {

			super( layer.getMapByName( "trees" ) );

			this.layer = layer;
			this.tileHits = tileHitMap;

			this.refreshMaps();

		} //

		/**
		 * only call this after the tileMaps for the layer have been loaded.
		 */
		public function refreshMaps():void {

			this.layerMaps = layer.getMaps();

			if ( this.lightMap == null ) {

				//this.lightMap = new BitmapData( terrain.cols, terrain.rows, false );
				this.initLightMap( this.tileMap.rows, this.tileMap.cols );

			}

		} //

		private function initLightMap( rows:int, cols:int ):void {

			this.lightRows = rows;
			this.lightCols = cols;

			this.lightMap = new Vector.< Vector.<int> >( rows, true );

			var lightRow:Vector.<int>;

			for( var r:int = 0; r < rows; r++ ) {

				lightRow = new Vector.<int>( cols, true );
				for( var c:int = 0; c < cols; c++ ) {
					lightRow[c] = 0;
				}

				this.lightMap[r] = lightRow;

			} // for-loop.

		} //

		override public function renderArea( eraseRect:Rectangle ):void {

			var t1:Number = getTimer();

			var minRow:int = Math.floor( eraseRect.y / this.tileSize ) - 2;
			var maxRow:int = Math.ceil( eraseRect.bottom / this.tileSize )+1;
			var minCol:int = Math.floor( eraseRect.x / this.tileSize )-2;
			var maxCol:int = Math.ceil( eraseRect.right / this.tileSize )+1;
			
			if ( minRow < 0 ) {
				minRow = 0;
			}
			if ( maxRow >= this.lightRows ) {
				maxRow = this.lightRows-1;
			} //
			if ( minCol < 0 ) {
				minCol = 0;
			}
			if ( maxCol >= this.lightCols ) {
				maxCol = this.lightCols-1;
			} //


			this.clearLightMap( minRow, minCol, maxRow, maxCol );

			this.computeLights( minRow-6, minCol-6, maxRow+6, maxCol+6 );

			this.renderLights( minRow, minCol, maxRow, maxCol );

			trace( "LIGHT DRAW TIME: " + (getTimer()-t1 ) );

		} //

		override public function render():void {

			var t1:Number = getTimer();

			//this.refreshSkyLights();

			this.clearLightMap( 0, 0, this.lightRows-1, this.lightCols-1 );

			this.computeLights( 0, 0, this.lightRows-1, this.lightCols-1 );

			this.renderLights( 0, 0, this.lightRows-1, this.lightCols-1 );

			trace( "WHOLE SCENE LIGHT DRAW TIME: " + (getTimer()-t1 ) );

		} //

		/**
		 * performs the actual rendering of the lights (actually shadows) to the view bitmap.
		 */
		public function renderLights( startRow:int, startCol:int, endRow:int, endCol:int ):void {

			var rc:RenderContext = this.renderContext;

			var tSize:int = this.tileSize;
			var type:TileType;

			rc.viewFillPane.filters = this.blurFilter;
			var graphics:Graphics = rc.viewGraphics;
			graphics.clear();
			//var t1:Number = getTimer();

			var x:int;
			var y:int = ( startRow + 0.5 )*tSize;

			for( var r:int = startRow; r <= endRow; r++ ) {

				x = ( startCol + 0.5 )*tSize;

				for( var c:int = startCol; c <= endCol; c++ ) {

					//gradMat.createGradientBox( 2*tileSize, 2*tileSize, 0, ( c-0.5)*tileSize, (r-0.5)*tileSize );
					//graphics.beginGradientFill( "radial", [0, 0], [0.6, 0], [0, 255], gradMat);
					graphics.beginFill( 0, 1 - ( this.lightMap[r][c]/255 ) );
					graphics.drawCircle( x, y, tSize/2 );
					graphics.endFill();

					x += tSize;

				} // col-loop.

				y += tSize;

			} // row-loop.

			rc.viewBitmap.draw( rc.viewFillPane, rc.viewMatrix, null, null, rc.viewPaintRect );
			graphics.clear();

			rc.viewFillPane.filters = rc.emptyFilters;

			//trace( "DRAW TIME: " + (getTimer()-t1 ) );

		} //

		/**
		 * Shadows are cast using a standard shadow-casting algorithm in which the light map is split into octants for more efficient traversal.
		 * 
		 * The first octant is from 0 to 45 degrees in the AS3 coordinate system ( positive x, positive y ) and octants 2,3,4... follow clockwise. 
		 */
		private function computeLights( minRow:int, minCol:int, maxRow:int, maxCol:int ):void {
			
			var light:int;

			if ( minRow < 0 ) {
				minRow = 0;
			}
			if ( minCol < 0 ) {
				minCol = 0;
			}

			if ( maxRow >= this.lightRows ) {
				maxRow = this.lightRows-1;
			}
			if ( maxCol >= this.lightCols ) {
				maxCol = this.lightCols-1;
			}

			for( var r:int = minRow; r <= maxRow; r++ ) {
				
				for( var c:int = minCol; c <= maxCol; c++ ) {
					
					light = this.getLightValue( r, c );
					if ( light > 0 ) {

						this.lightMap[r][c] += light;
						if ( c+1 < this.lightCols ) {
							this.castShadows1( r, c, r, c+1, Number.MAX_VALUE, light );
							if ( r-1 >= 0 ) {
								this.castShadows4( r, c, r-1, c+1, Number.MAX_VALUE, light );
							}
						}
						if ( r+1 < this.lightRows ) {
							this.castShadows2( r, c, r+1, c, Number.MAX_VALUE, light );
						} //
						
					} //
					
				} // for-loop.
				
			} // for-loop.
			
		} //

		/**
		 * sourceRow, sourceCol is the row,col of the light source ( assuming 32pixel tiles )
		 * increment by row
		 * constant column.
		 * slopes are currently given dy/dx
		 * 
		 * minSlope < (dr+0.5)*tileSize / ( dc+0.5)*tileSize < maxSlope   <-- premultiply by constant column to save time.
		 */
		private function castShadows1( sourceRow:int, sourceCol:int, row:int, col:int, maxSlope:Number, light:int ):void {

			// premultiply slope bounds.
			var multMax:Number = maxSlope*(col-sourceCol);

			/**
			 * whether the current line being scanned is filled ( opaque ) to light or not.
			 * whenever this value toggles, recursion fills in all the values for the next column.
			 */
			var scanningFilled:Boolean = false;

			/**
			 * row where the current line of filled or empty tiles began. (recursion begins at this value)
			 */
			var scanStart:int = row;
			var lightPropagate:int;

			while ( (row-sourceRow) < multMax ) {

				if ( this.tileHits.isEmptyTile( row, col ) ) {

					// EMPTY TILE SCANNED

					if ( scanningFilled ) {

						// line was tracking filled spaces and now we reached an empty space.
						// need to recursively fill the shadow of the opaque spaces.
						/**lightPropagate = light - this.lightSolidDecay;
						if ( col + 1 < this.lightCols && lightPropagate > this.minLightStrength ) {
							this.castShadows1( sourceRow, sourceCol, scanStart, col + 1, minSlope, maxSlope, lightPropagate );
						}*/
						// new min slope:  is this right?
						//minSlope = ( row - (sourceRow + 0.5) ) / ( col - (sourceCol + 0.5) );
						// this row/scanRow are both wrong: need a loop to find the correct next-row.
						scanStart = row;
						scanningFilled = false;

					} else {
						
						this.lightMap[row][col] += light;

					} //

				} else {

					// FILLED TILE SCANNED
					// no matter what, the light hits the filled tile.
					this.lightMap[row][col] += light;

					if ( scanningFilled == false ) {

						// had been empty up to this point.
						lightPropagate = light - this.lightAirDecay;
						if ( ((col+1) < this.lightCols) && (lightPropagate > this.minLightStrength) ) {
							this.castShadows1( sourceRow, sourceCol, scanStart, col+1, ( row - (sourceRow + 0.5) ) / ( col - sourceCol + 0.5 ), lightPropagate );
						}
						scanStart = row;		// next scan starts from here.
						scanningFilled = true;

					}

				} //

				light -= this.lightAirDecay;
				if ( ++row >= this.lightRows || light < this.minLightStrength ) {
					break;
				}

			} // while-loop.

			// light remaining.
			if ( scanningFilled == false && col+1 < this.lightCols ) {
				lightPropagate = light - this.lightAirDecay;
				if ( lightPropagate > this.minLightStrength ) {
					this.castShadows1( sourceRow, sourceCol, scanStart, col+1, maxSlope, lightPropagate );
				}
			}

		} //

		/**
		 * second quadrant lighting. col-sourceCol is negative so slopes have to be reversed.
		 */
		private function castShadows2( sourceRow:int, sourceCol:int, row:int, col:int, maxSlope:Number, light:int ):void {

			// premultiply slope bounds.
			var multMax:Number = maxSlope*(row-sourceRow);

			/**
			 * whether the current line being scanned is filled ( opaque ) to light or not.
			 * whenever this value toggles, recursion fills in all the values for the next column.
			 */
			var scanningFilled:Boolean = false;
			
			/**
			 * row where the current line of filled or empty tiles began. (recursion begins at this value)
			 */
			var scanStart:int = row;
			var lightPropagate:int;
			
			while ( (sourceCol-col) < multMax ) {
				
				if ( this.tileHits.isEmptyTile( row, col ) ) {
					
					// EMPTY TILE SCANNED
					this.lightMap[row][col] += light;
					
					if ( scanningFilled ) {
						
						// line was tracking filled spaces and now we reached an empty space.
						// need to recursively fill the shadow of the opaque spaces.

						scanStart = col;
						scanningFilled = false;
						
					} //
					
				} else {
					
					// FILLED TILE SCANNED
					this.lightMap[row][col] += light;
					
					if ( scanningFilled == false ) {
						
						// had been empty up to this point.
						lightPropagate = light - this.lightAirDecay;
						if ( (lightPropagate > this.minLightStrength) && ((row+1) < this.lightRows) ) {
							this.castShadows2( sourceRow, sourceCol, row+1, scanStart, ( sourceCol - 0.5 - col ) / ( row + 0.5 - sourceRow ), lightPropagate );
						}
						scanStart = col;		// next scan starts from here.
						scanningFilled = true;
						
					}
					
				} //
				
				light -= this.lightAirDecay;
				if ( --col < 0 ) {
					break;
				}
				
			} // while-loop.
			
			// light remaining.
			if ( scanningFilled == false && col+1 < this.lightCols ) {
				lightPropagate = light - this.lightAirDecay;
				if ( lightPropagate > this.minLightStrength ) {
					this.castShadows2( sourceRow, sourceCol, row+1, scanStart, maxSlope, lightPropagate );
				}
			}
			
		} //

		/**
		 * row-sourceRow < 0 so the slope is reversed.
		 */
		private function castShadows4( sourceRow:int, sourceCol:int, row:int, col:int, maxSlope:Number, light:int ):void {
			
			// premultiply slope bounds.
			var multMax:Number = maxSlope*(col-sourceCol);

			/**
			 * whether the current line being scanned is filled ( opaque ) to light or not.
			 * whenever this value toggles, recursion fills in all the values for the next column.
			 */
			var scanningFilled:Boolean = false;
			
			/**
			 * row where the current line of filled or empty tiles began. (recursion begins at this value)
			 */
			var scanStart:int = row;
			var lightPropagate:int;
			
			while ( (sourceRow-row) < multMax ) {
				
				if ( this.tileHits.isEmptyTile( row, col ) ) {
					
					// EMPTY TILE SCANNED
					this.lightMap[row][col] += light;
					
					if ( scanningFilled ) {
						
						// line was tracking filled spaces and now we reached an empty space.
						// need to recursively fill the shadow of the opaque spaces.
						scanStart = row;
						scanningFilled = false;
						
					} //
					
				} else {
					
					// FILLED TILE SCANNED
					this.lightMap[row][col] += light;
					
					if ( scanningFilled == false ) {
						
						// had been empty up to this point.
						lightPropagate = light - this.lightAirDecay;
						if ( ((col+1) < this.lightCols) && (lightPropagate > this.minLightStrength) ) {
							this.castShadows4( sourceRow, sourceCol, scanStart, col+1, ( sourceRow - row - 0.5 ) / ( col - sourceCol + 0.5 ), lightPropagate );
						}
						scanStart = row;		// next scan starts from here.
						scanningFilled = true;
						
					}
					
				} //
				
				light -= this.lightAirDecay;
				if ( --row < 0 ) {
					break;
				}
				
			} // while-loop.
			
			// light remaining.
			if ( scanningFilled == false && col+1 < this.lightCols ) {
				lightPropagate = light - this.lightAirDecay;
				if ( lightPropagate > this.minLightStrength ) {
					this.castShadows4( sourceRow, sourceCol, scanStart, col+1, maxSlope, lightPropagate );
				}
			}
			
		} //

		private function getLightValue( r:int, c:int ):int {

			var tmap:TileMap;
			var type:TileType;

			for( var i:int = this.layerMaps.length-1; i >= 0; i-- ) {

				tmap = this.layerMaps[i];
				if ( tmap.tileSize != 32 ) {
					// currently only the 32-size maps have lights.
					continue;
				}
				type = tmap.getTypeAt( r, c );
				if ( type == null ) {
					continue;
				}
				return type.light;

			} //

			return 0;

		} //

		/**
		 * clears a range of the light map. does not perform bounds checking.
		 */
		private function clearLightMap( row:int, minCol:int, maxRow:int, maxCol:int ):void {
			
			for( ; row <= maxRow; row++ ) {
				
				for( var c:int = minCol; c <= maxCol; c++ ) {
					this.lightMap[row][c] = 0;
				} //
				
			} //
			
		} //

		/*private function applyLight( sourceRow:int, sourceCol:int, minRow:int, minCol:int, maxRow:int, maxCol:int ):void {
		} //*/

		/**
		 * straight-down lights.
		 */
		/*public function refreshSkyLights():void {

			var map:TileMap = this.tileMap;
			var bm:BitmapData = this.lightMap;

			// everything starts dark.
			bm.fillRect( bm.rect, this._darkAlpha );

			var rows:Number = map.rows;
			var cols:Number = map.cols;

			var tiles:Vector.< Vector.<LandTile> > = map.getTiles();

			var curRow:Vector.<LandTile>;
			var nextRow:Vector.<LandTile> = tiles[0];

			var colAlpha:int;
			var fading:Boolean;			// once we hit something in that column, it's fading.

			// light from above.
			for( var c:int = cols-1; c >= 0; c-- ) {

				// no shadows in column - start at sky brightness.
				colAlpha = this._skyAlpha;
				fading = false;
			
				for( var r:int = 0; r < rows; r++ ) {

					bm.setPixel( c, r, colAlpha );

					if ( tiles[r][c].type != 0 ) {

						fading = true;
						colAlpha += 40;
						if ( colAlpha >= this._darkAlpha ) {
							// already as dark as it can get.
							break;
						}

					} else if ( fading ) {

						// drop-off for fading but not currently hitting something solid is less extreme.
						colAlpha += 20;
						if ( colAlpha >= this._darkAlpha ) {
							// already as dark as it can get.
							break;
						}
			
					} //
			
				} // for-loop.
			
			} // for-loop.
		
		} //*/
		
	} // class
	
} // package