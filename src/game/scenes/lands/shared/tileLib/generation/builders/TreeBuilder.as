package game.scenes.lands.shared.tileLib.generation.builders {

	/**
	 * This class is to generate different trees on a tile map,
	 * unlike generators which generate features over the whole map?
	 */
	import flash.geom.Point;
	
	import game.scenes.lands.shared.tileLib.LandTile;
	import game.scenes.lands.shared.tileLib.TileMap;
	import game.scenes.lands.shared.tileLib.generation.data.TreeData;
	import game.scenes.lands.shared.tileLib.generation.data.TreeLine;
	import game.scenes.lands.shared.tileLib.generation.generators.MapGenerator;

	public class TreeBuilder extends MapGenerator {

		public var leafTile:uint;
		public var trunkTile:uint;

		public function TreeBuilder( tmap:TileMap ) {

			super( tmap );

		} //

		public function build( r:int, c:int, type:TreeData ):void {
		} //

		/**
		 * this function takes a branch and treats it as a polygon, using its endpoints and width
		 * to create the polgyon boundaries. it then fills that polgygon with the scan-line bresenham algorithm.
		 * 
		 * the problem with scan-line fills is that you need to clip the polygon at the screen boundaries.
		 * to avoid that, this function just moves the clipped points back into the screen bounds
		 * even though this produces incorrect lines. its okay because trees are inherently chaotic
		 * and because the actual boundary lines are off-screen anyway.
		 */
		protected function scanLineFillBranch( branch:TreeLine ):void {

			var pts:Array = this.prepareFillPoints( branch );
			var startIndex:int = this.findMinY( pts );

			var index0:int = ( startIndex - 1 ) & 3;
			var index1:int = ( startIndex + 1 ) & 3;

			var pStart:Point = pts[startIndex];
			var p0:Point = pts[index0];
			var p1:Point = pts[index1];
			
			var x0:int = pStart.x;
			var y0:int = pStart.y;
			
			var x1:int = x0;
			var y1:int = y0;
			
			var xInc0:int, yInc0:int;			// Increment variables.
			var xInc1:int, yInc1:int;
			
			var error0:int, error1:int;
			var count0:int, count1:int;
			
			var edgeCount:int = 4;
			
			do {
				
				var dx0:int = p0.x - x0;
				var dy0:int = p0.y - y0;
				
				var dx1:int = p1.x - x1;
				var dy1:int = p1.y - y1;
				
				if ( dx0 > 0 ) {
					xInc0 = 1;
				} else if ( dx0 < 0 ) {
					dx0 = -dx0;
					xInc0 = -1;
				} else {
					xInc0 = 0;
				}

				if ( dy0 > 0 ) {
					yInc0 = 1;
				} else if ( dy0 < 0 ) {
					dy0 = -dy0;
					yInc0 = -1;
				} else {
					yInc0 = 0;
				}
				
				if ( dx1 > 0 ) {
					xInc1 = 1;
				} else if ( dx1 < 0 ) {
					dx1 = -dx1;
					xInc1 = -1;
				}  else {
					xInc1 = 0;
				}

				if ( dy1 > 0 ) {
					yInc1 = 1;
				} else if ( dy1 < 0 ) {

					dy1 = -dy1;
					yInc1 = -1;

				} else {
					yInc1 = 0;
				}
				
				if ( dx0 > dy0 ) {
					
					if ( dx1 > dy1 ) {
						
						error0 = count0 = dx0;
						error1 = count1 = dx1;
						
						while( count0 > 0 && count1 > 0 ) {
							
							while( count0-- > 0 && error0 > 0 ) {
								
								this.fillTrunkTile( this.tileMap.getTile( y0, x0 ) );
								
								x0 += xInc0;
								error0 -= dy0;
								
							} //
							
							while( count1-- > 0 && error1 > 0 ) {
								
								this.fillTrunkTile( this.tileMap.getTile( y1, x1 ));
								
								x1 += xInc1;
								error1 -= dy1;
								
							} //
							
							// got the y-value.
							y0 += yInc0;
							error0 += dx0;
							
							// got the y-value.
							y1 += yInc1;
							error1 += dx1;
							
							this.drawScanLine( x0, x1, y1, this.trunkTile );
							
						} // while()
						
					} else {
						
						// dx1 < dy1. move in x0, y1
						
						error0 = count0 = dx0;
						error1 = count1 = dy1;
						
						while ( count0 > 0 && count1-- > 0 ) {
							
							while( count0-- > 0 && error0 > 0 ) {
								
								this.fillTrunkTile( this.tileMap.getTile( y0, x0 ));
								
								x0 += xInc0;
								error0 -= dy0;
							} //
							
							// got the y-value.
							y0 += yInc0;
							error0 += dx0;
							
							y1 += yInc1;
							error1 -= dx1;
							if ( error1 <= 0 ) {
								x1 += xInc1;
								error1 += dy1;
							}
							
							this.drawScanLine( x0, x1, y1, this.trunkTile );
							
						} // while
						
					} //
					
				} else {
					
					// dx0 < dy0
					if ( dx1 > dy1 ) {
						
						// move in y0, x1
						
						error0 = count0 = dy0;
						error1 = count1 = dx1;
						
						this.fillTrunkTile( this.tileMap.getTile( y1, x1 ) );
						
						while ( count0-- > 0 && count1 > 0 ) {
							
							y0 += yInc0;
							error0 -= dx0;
							
							if ( error0 <= 0 ) {
								x0 += xInc0;
								error0 += dy0;
							}
							
							while( count1-- > 0 && error1 > 0 ) {
								
								this.fillTrunkTile( this.tileMap.getTile( y1, x1 ) );
								
								x1 += xInc1;
								error1 -= dy1;
								
							} //
							
							// got the y-value.
							y1 += yInc1;
							error1 += dx1;
							
							this.drawScanLine( x0, x1, y1, this.trunkTile );
							
						} // while
						
					} else {
						
						error0 = count0 = dy0;
						error1 = count1 = dy1;
						
						// need this here because the first loop moves y before a fill.
						this.fillTrunkTile( this.tileMap.getTile( y0, x0 ));
						
						// dx1 < dy1, dx0 < dy0 -> loop in y-values.
						while ( count0-- > 0 && count1-- > 0 ) {
							
							y0 += yInc0;
							error0 -= dx0;
							
							y1 += yInc1;
							error1 -= dx1;
							
							if ( error0 <= 0 ) {
								x0 += xInc0;
								error0 += dy0;
							}
							if ( error1 <= 0 ) {
								x1 += xInc1;
								error1 += dy1;
							}
							
							this.drawScanLine( x0, x1, y0, this.trunkTile );
							
						} // while
						
					} //
					
				} // end ifs that branch dx's dy's
				
				if ( count0 <= 0 ) {
					
					index0 = ( index0 - 1 ) & 3;
					p0 = pts[index0];
					
					edgeCount--;
					
				} //
				
				if ( count1 <= 0 ) {
					
					index1 = ( index1 + 1 ) & 3;
					p1 = pts[index1];
					
					edgeCount--;
					
				} //
				
			} while ( edgeCount > 0 );
			
		} //
		
		/**
		 * bresenham line with bounds check based on tileMap boundaries.
		 * just draws a line of the given tile type through the tileMap.
		 * the thickness is roughly one tile wide, but can look larger depending on the angle of the line.
		 */
		protected function boundedLine( x0:int, y0:int, x1:int, y1:int, type:uint ):void {
			
			var dx:int = x1 - x0;
			var dy:int = y1 - y0;
			
			// First section is all bounds checking.
			if ( x0 < 0 ) {
				
				if( x1 < 0 ) {
					return;		// both coords off screen.
				}
				y0 = (dy/dx)*(-x0) + y0;
				x0 = 0;
				
			} else if ( x0 >= this.tileMap.cols ) {
				
				if ( x1 >= this.tileMap.cols ) {
					return;
				}
				y0 = (dy/dx)*( this.tileMap.cols-1 - x0) + y0;
				x1 = this.tileMap.cols-1;
				
			} //
			
			if ( x1 < 0 ) {
				y1 = (dy/dx)*(-x1) + y1;
				x1 = 0;
			} else if ( x1 >= this.tileMap.cols ) {
				y1 = (dy/dx)*( this.tileMap.cols-1 - x1) + y1;
				x1 = this.tileMap.cols-1;
			} //
			
			if ( y0 < 0 ) {
				
				if( y1 < 0 ) {
					return;		// both coords off screen.
				}
				x0 = (dx/dy)*(-y0) + x0;
				y0 = 0;
				
			} else if ( y0 >= this.tileMap.rows ) {
				
				if ( y1 >= this.tileMap.rows ) {
					return;
				}
				x0 = (dx/dy)*( this.tileMap.rows-1 - y0) + x0;
				y0 = this.tileMap.rows-1;
				
			} //
			
			if ( y1 < 0 ) {
				x1 = (dx/dy)*(-y1) + x1;
				y1 = 0;
			} else if ( y1 >= this.tileMap.rows ) {
				y1 = (dx/dy)*( this.tileMap.rows-1 - y1) + x1;
				y1 = this.tileMap.rows-1;
			} //
			
			dx = Math.abs(dx);
			dy = Math.abs(dy);
			
			var inc:int;			// increment for the other variable.
			var error:int;
			
			if ( dx > dy ) {
				
				if ( y1 > y0 ) {
					inc = 1;
				} else if ( y0 > y1 ) {
					inc = -1;
				} else {
					inc = 0;
				}
				
				error = dx;
				
				if ( x1 > x0 ) {
					
					while( x0 <= x1 ) {
						
						this.tileMap.fillTypeAt( y0, x0, type );
						x0++;
						error -= dy;
						if ( error <= 0 ) {
							error += dx;
							y0 += inc;
						} //
						
					} //
					
				} else {
					
					// x0 > x1
					while( x0 >= x1 ) {
						
						this.tileMap.fillTypeAt( y0, x0, type );
						
						x0--;
						error -= dy;
						if ( error <= 0 ) {
							error += dx;
							y0 += inc;
						} //	
						
					} //
					
				} // end-if.
				
			} else {
				
				if ( x1 > x0 ) {
					inc = 1;
				} else if ( x0 > x1 ) {
					inc = -1;
				} else {
					inc = 0;
				}
				
				error = dy;
				
				if ( y1 > y0 ) {
					
					while( y0 <= y1 ) {
						
						this.tileMap.fillTypeAt( y0, x0, type );
						
						y0++;
						error -= dx;
						if ( error <= 0 ) {
							error += dy;
							x0 += inc;
						} //
						
					} //
					
				} else {
					
					// y0 > y1
					while( y0 >= y1 ) {
						
						this.tileMap.fillTypeAt( y0, x0, type );
						
						y0--;
						error -= dx;
						if ( error <= 0 ) {
							error += dy;
							x0 += inc;
						} //	
						
					} //
					
				} // end-if.
				
			} // end-if.
			
		} // ()
		
		/**
		 * BRESENHAM'S FRICKING LINE.
		 * 
		 * bresenham's line with no bounds checking.
		 */
		protected function bresenham( x0:int, y0:int, x1:int, y1:int, type:uint ):void {
			
			var dx:int = Math.abs( x1 - x0 );
			var dy:int = Math.abs( y1 - y0 );
			
			var inc:int;			// increment for the other variable.
			var error:int;
			
			if ( dx > dy ) {
				
				if ( y1 > y0 ) {
					inc = 1;
				} else if ( y0 > y1 ) {
					inc = -1;
				} else {
					inc = 0;
				}
				
				error = dx;
				
				if ( x1 > x0 ) {
					
					while( x0 <= x1 ) {
						
						this.tileMap.fillTypeAt( y0, x0, type );
						
						x0++;
						error -= dy;
						if ( error < 0 ) {
							error += dx;
							y0 += inc;
						} //
						
					} //
					
				} else {
					
					// x0 > x1
					while( x0 >= x1 ) {
						
						this.tileMap.fillTypeAt( y0, x0, type );
						x0--;
						error -= dy;
						if ( error < 0 ) {
							error += dx;
							y0 += inc;
						} //	
						
					} //
					
				} // end-if.
				
			} else {
				
				if ( x1 > x0 ) {
					inc = 1;
				} else if ( x0 > x1 ) {
					inc = -1;
				} else {
					inc = 0;
				}
				
				error = dy;
				
				if ( y1 > y0 ) {
					
					while( y0 <= y1 ) {
						
						this.tileMap.fillTypeAt( y0, x0, type );
						y0++;
						error -= dx;
						if ( error < 0 ) {
							error += dy;
							x0 += inc;
						} //
						
					} //
					
				} else {
					
					// y0 > y1
					while( y0 >= y1 ) {
						
						this.tileMap.fillTypeAt( y0, x0, type );
						y0--;
						error -= dx;
						if ( error < 0 ) {
							error += dy;
							x0 += inc;
						} //	
						
					} //
					
				} // end-if.
				
			} // end-if.
			
		} // bresenhamLine()

		/**
		 * creates bounding points for a fill line - turning the line into a quad polygon defined by four corner points.
		 */
		protected function prepareFillPoints( branch:TreeLine ):Array {
			
			var dx:Number = branch.halfThickness*branch.dx;
			var dy:Number = branch.halfThickness*branch.dy;
			
			var pts:Array = new Array();
			
			pts.push( new Point( branch.startPt.x - dy, branch.startPt.y + dx ) );
			pts.push( new Point( branch.startPt.x + dy, branch.startPt.y - dx ) );
			
			dx = branch.endThickness*branch.dx;
			dy = branch.endThickness*branch.dy;
			
			// note the inverse order of the normals so the points are sequential.
			pts.push( new Point( branch.endPt.x + dy, branch.endPt.y - dx ) );
			pts.push( new Point( branch.endPt.x - dy, branch.endPt.y + dx ) );
			
			var p:Point;
			
			for( var i:int = 3; i >= 0; i-- ) {
				
				p = pts[i];
				if ( p.x < 0 ) {
					p.x = 0;
				} else if ( p.x >= this.tileMap.cols ) {
					p.x = this.tileMap.cols-1;
				}
				
				if ( p.y < 0 ) {
					p.y = 0;
				} else if ( p.y >= this.tileMap.rows ) {
					p.y = this.tileMap.rows-1;
				}
				
			} //
			
			return pts;
			
		} //

		protected function fillTreeTile( tile:LandTile, type:uint ):void {

			tile.type |= type;

		} //

		protected function fillTrunkTile( tile:LandTile ):void {

			tile.type |= this.trunkTile;
			
		} //

		/**
		 * draws a line across the tileMap - row held constant and going from x0 to x1.
		 */
		protected function drawScanLine( x0:int, x1:int, y:int, type:uint ):void {
			
			var tile:LandTile;
			var row:Vector.<LandTile> = this.tileMap.getTiles()[y];
			
			if ( x0 < x1 ) {
				
				while ( x0 <= x1 ) {
					
					tile = row[x0++];
					tile.type |= type;
					
				} //
				
			} else {
				
				while( x1 <= x0 ) {
					
					tile = row[x1++];
					tile.type |= type;
					
				} //
				
			} //
			
		} // drawScanLine()
		
		/**
		 * from an array of points, returns index with minimum y-value.
		 
		 */
		protected function findMinY( pts:Array ):int {
			
			var minIndex:int = pts.length-1;			
			var minY:Number = pts[ minIndex ];
			
			for( var i:int = minIndex-1; i >= 0; i-- ) {
				
				if ( pts[i].y < minY ) {
					minIndex = i;
					minY = pts[i].y;
				} //
				
			} //
			
			return minIndex;
			
		} //

		
		protected function fillLeafRow( minCol:int, maxCol:int, row:int ):void {
			
			if ( minCol > maxCol ) {
				var c:int = maxCol;
				maxCol = minCol;
				minCol = c;
			}
			
			if ( minCol < 0 ) {
				minCol = 0;
			}
			if ( maxCol >= this.tileMap.cols ) {
				maxCol = this.tileMap.cols - 1;
			}
			
			for( c = minCol; c <= maxCol; c++ ) {
				this.tileMap.getTile( row, c ).type |= this.leafTile;
			} //
			
		} //

	} // class

} // package