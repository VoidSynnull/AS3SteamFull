package game.scenes.lands.shared.classes {

	import flash.display.BitmapData;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Spatial;
	
	import game.scenes.lands.shared.tileLib.LandTile;
	import game.util.CharUtils;

	/**
	 * this class just takes a bitmap and tells if there is a hit there
	 * according to a given tileSize.
	 * 
	 * Before hits are tested, conversions must be done from tile row,cols or screen x,y
	 * coordinates to the scaled bitmap coordinates. this makes some of the code a bit confusing.
	 * 
	 */

	public class TileBitmapHits {

		/**
		 * hits bitmap.
		 */
		private var bitmap:BitmapData;

		/**
		 * bitmap scaling (hit bitmaps are scaled down to save memory)
		 */
		private var bitmapScale:Number;

		/**
		 * tileMaps are offset from 0,0 so they go offscreen slightly.
		 * any tile offscreen will currently be counted as not hittable.
		 * this is the POSITIVE amount by which the tileMaps are shifted to the LEFT.
		 */
		private var mapOffsetX:int;

		/**
		 * mapOffsetX after bitmap scaling has been applied.
		 */
		private var _scaleOffset:Number;

		private var tileSize:int = 32;

		/**
		 * scaled tile size ( the tile size in the bitmap. )
		 * this is the tilesize times the bitmap scale, cached for speed.
		 */
		private var _tscale:Number;

		public function setTileSize( tsize:int ):void {

			this.tileSize = tsize;
			this._tscale = tsize*this.bitmapScale;

		} //

		public function TileBitmapHits( hitBitmap:BitmapData, bm_scale:Number, mapOffset:int ) {

			this.bitmap = hitBitmap;
			this.bitmapScale = bm_scale;
			this._tscale = this.tileSize*bm_scale;

			this.mapOffsetX = mapOffset;
			this._scaleOffset = mapOffset*bm_scale;

		} //

		/**
		 * Find the first row with no hits in the given column
		 */
		public function findTopEmpty( c:int ):int {

			var tscale:Number = this._tscale;

			var x:Number = -this._scaleOffset + tscale*( c + 0.5 );
			var y:Number = 0.5*tscale;
			
			while ( this.bitmap.getPixel( x, y ) != 0 ) {

				y += tscale;
				if ( y > this.bitmap.height ) {
					break;
				}

			}
			
			return int( y / tscale );

		} //

		/**
		 * returns the map point associated with the given row,col of the tileMap.
		 */
		public function getMapPoint( r:int, c:int ):Point {

			return new Point( -this.mapOffsetX + c*this.tileSize, r*this.tileSize );

		} //

		public function getTilePoint( tile:LandTile ):Point {

			return new Point( -this.mapOffsetX + tile.col*this.tileSize, tile.row*this.tileSize );

		} //

		public function getTileCenter( tile:LandTile ):Point {
			
			return new Point( -this.mapOffsetX + ( tile.col + 0.5 )*this.tileSize, ( tile.row + 0.5 )*this.tileSize );
			
		} //

		/**
		 * find the first filled row in the given column.
		 * returns the last row ( or last row + 1 from rounding ) if all are empty.
		 */
		public function findTopFilled( c:int ):int {

			var tscale:Number = this._tscale;

			var x:Number = -this._scaleOffset + tscale*( c + 0.5 );
			var y:Number = 0.5*tscale;

			while ( this.bitmap.getPixel( x, y ) == 0 ) {

				y += tscale;
				if ( y > this.bitmap.height ) {
					break;
				}

			}

			return int( y / tscale );

		} //

		/**
		 * for the given tile row, finds the x-coordinate of the first blocked tile.
		 * 
		 * if direction > 0, the map is checked for blocked tiles from left to right
		 * if direction < 0 the map checks the right side of the scene and moves left, checking for blocked tiles.
		 */
		public function findBlockedX( r:int, direction:int=1 ):Number {

			var tscale:Number = this._tscale;
			
			var x:Number;
			var y:Number = ( r + 0.5 )*tscale;

			if ( direction > 0 ) {

				x = 0.5*tscale;

				while ( this.bitmap.getPixel( x, y ) == 0 ) {
					
					x += tscale;
					if ( x > this.bitmap.width ) {
						break;
					}

				}

			} else {

			 	x = ( this.bitmap.width - 0.5*tscale );

				while ( this.bitmap.getPixel( x, y ) == 0 ) {

					x -= tscale;
					if ( x < 0 ) {
						break;
					}
				}

			}

			return ( x/this.bitmapScale );

		} //

		public function getHitAt( x:Number, y:Number ):uint {

			return this.bitmap.getPixel( x*this.bitmapScale, y*this.bitmapScale );

		} //

		/**
		 * returns the y-value of the first filled tile at a given x-location.
		 * 
		 * the x here is relative to scene coordinates, not tile coordinates.
		 */
		public function findTopY( x:Number ):Number {

			x *= this.bitmapScale;
			var tscale:Number = this._tscale;
			var y:Number = 0.5*tscale;

			while ( this.bitmap.getPixel( x, y ) == 0 ) {

				y += tscale;
				if ( y > this.bitmap.height ) {
					break;
				}

			} //

			return y/this.bitmapScale;

		} //

		/**
		 * this actually just tests a scene coordinate against the bitmap directly.
		 */
		public function isEmpty( x:int, y:int ):Boolean {

			return ( this.bitmap.getPixel( x*this.bitmapScale, y*this.bitmapScale ) == 0 );

		} //

		public function isEmptyTile( r:int, c:int ):Boolean {

			var tscale:Number = this._tscale;

			return ( this.bitmap.getPixel( this._scaleOffset + tscale*( c + 0.5 ), tscale*( r + 0.5 ) ) == 0 );

		} //

		/**
		 * performs a search on the bitmap, attempting to find a clear ground-path in a given direction.
		 * needs to be fixed for better accuracy.
		 * 
		 * e is the entity attempting to move to the target.
		 * spatial is the entity's spatial.
		 * colDir is the change in the column - -1 or +1 for testing left and right.
		 */
		public function directionSearch( e:Entity, spatial:Spatial, xDir:int, maxColDist:int=8, maxSlope:int=8 ):void {
			
			var tscale:Number = this._tscale;
			
			// get center of current virtual 'tile'
			var x:Number = tscale * ( Math.floor( ( spatial.x - this.mapOffsetX ) / this.tileSize ) + 0.5 );
			var y:Number = tscale * ( Math.floor( spatial.y / this.tileSize ) + 0.5 );
			
			// lastX,lastY will save the last known 'good' walking location.
			var lastX:Number = x = x + this._scaleOffset;
			var lastY:Number = y;
			y += tscale;
			
			var ycutoff:Number;
			var blocked:Boolean = false;
			
			xDir *= tscale;			// premultiply the x-direction step by the tile scaling.
			
			while ( maxColDist-- > 0 ) {
				
				x += xDir;
				if ( x < 0 ) {
					x = tscale;
					break;
				} else if ( x >= this.bitmap.width ) {
					x = this.bitmap.width - tscale;
					break;
				} //
				
				if ( this.bitmap.getPixel( x, y ) != 0 ) {
					
					// ground hit in this space. look up until theres an open-air space.
					
					ycutoff = y - maxSlope*tscale;
					do {
						y -= tscale;
						if ( y < ycutoff ) {
							blocked = true;
							break;
						} //
						
					} while ( this.bitmap.getPixel( x, y ) != 0 );
					
				} else {
					
					ycutoff = y + maxSlope*tscale;
					
					// empty air in this space. go down until you see a landing spot.
					do {
						
						y += tscale;
						if ( y > ycutoff ) {
							blocked = true;
							break;
						}
						
					} while ( this.bitmap.getPixel( x, y ) == 0 );
					
				} //
				
				// too steep a slope. stop now.
				if ( blocked ) {
					CharUtils.moveToTarget( e, lastX/this.bitmapScale, (lastY)/this.bitmapScale );
					break;
				} else {
					lastX = x;
					lastY = y;
				}
				
			} // while-loop.
			
			CharUtils.moveToTarget( e, x/this.bitmapScale, ( y )/this.bitmapScale );
			
			//trace( "new target : " + newTarget.targetX + "," + newTarget.targetY );
			
		} // groundSearch()

		/**
		 * tests for a clear path in the scene from startX, startY to endX, endY
		 * needs to be cleaned up.
		 *
		 *  returns true if line was blocked at some point, false otherwise.
		 * 	the endpoint is adjusted to be before the blocked point.
		 */
		public function lineTest( startX:Number, startY:Number, endPt:Point ):Boolean {

			var endTest:Number;

			// dx / ( this.tileSize/2 )
			var dx:Number = this.bitmapScale*( 2*(endPt.x - startX)/this.tileSize );
			var dy:Number = this.bitmapScale*( 2*(endPt.y - startY)/this.tileSize );

			var x:Number = this.bitmapScale*startX;
			var y:Number = this.bitmapScale*startY;

			// blocked from the start.
			if ( this.bitmap.getPixel( x, y ) != 0 ) {
				return true;
			}

			x += dx;
			y += dy;

			if ( Math.abs( dx ) > Math.abs(dy) ) {

				// moving by x-amount, so the test is vs the end-x coordinate.
				endTest = endPt.x * this.bitmapScale;

				if ( dx > 0 ) {

					while ( x < endTest ) {
						if ( this.bitmap.getPixel( x, y ) != 0 ) {
							// move back to the last unblocked space; set block space and returned blocked=true
							endPt.setTo( ( x - dx )/this.bitmapScale, ( y - dy)/this.bitmapScale );
							return true;
						}
						x += dx; y += dy;
					} //

				} else {

					while ( x > endTest ) {

						if ( this.bitmap.getPixel( x, y ) != 0 ) {
							// move back to the last unblocked space; set block space and returned blocked=true
							endPt.setTo( ( x - dx )/this.bitmapScale, ( y - dy)/this.bitmapScale );
							return true;
						}
						x += dx; y += dy;
					} //

				} //

			} else {

				endTest = endPt.y * this.bitmapScale;

				if ( dy > 0 ) {

					while ( y < endTest ) {

						if ( this.bitmap.getPixel( x, y ) != 0 ) {
							// move back to the last unblocked space; set block space and returned blocked=true
							endPt.setTo( ( x - dx )/this.bitmapScale, ( y - dy)/this.bitmapScale );
							return true;
						}
						x += dx; y += dy;

					} //

				} else {

					while ( y >= endTest ) {

						if ( this.bitmap.getPixel( x, y ) != 0 ) {
							// move back to the last unblocked space; set block space and returned blocked=true
							endPt.setTo( ( x - dx )/this.bitmapScale, ( y - dy)/this.bitmapScale );
							return true;
						}

						x += dx; y += dy;

					} // while-loop.

				} // dy <= 0

			} // ( dx / dy ) comparison

			return false;

		} //

	} // class
	
} // package