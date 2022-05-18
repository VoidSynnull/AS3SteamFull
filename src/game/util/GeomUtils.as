/*****************************************************
 * Geom Utils
 * 
 * Author : Gabriel Jensen
 * Date : 9/30/12
 
 * ***************************************************/

package game.util
{
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import engine.components.Spatial;
	
	public class GeomUtils
	{
		public static function getRandomPointInRectangle(rectangle:Rectangle):Point
		{
			var point:Point = new Point();
			
			point.x = Utils.randNumInRange(rectangle.left, rectangle.right);
			point.y = Utils.randNumInRange(rectangle.top, rectangle.bottom);
			
			return point;
		}
		
		public static function getPointWithinRects(outer:Rectangle, inner:Rectangle):Point
		{
			var x:Number;
			var y:Number;
			var random:Number = Math.random();
			
			//Left
			if(random >= 0 && random < 0.25)
			{
				x = Utils.randNumInRange(outer.left, inner.left);
				y = Utils.randNumInRange(outer.top, outer.bottom);
			}
			//Top
			else if(random >= 0.25 && random < 0.5)
			{
				x = Utils.randNumInRange(outer.left, outer.right);
				y = Utils.randNumInRange(outer.top, inner.top);
			}
			//Right
			else if(random >= 0.5 && random < 0.75)
			{
				x = Utils.randNumInRange(inner.right, outer.right);
				y = Utils.randNumInRange(outer.top, outer.bottom);
			}
			//Bottom
			else
			{
				x = Utils.randNumInRange(outer.left, outer.right);
				y = Utils.randNumInRange(inner.bottom, outer.bottom);
			}
			
			return new Point(x, y);
		}
		
		public static function getRandomPositionOutside(x:Number, y:Number, width:Number, height:Number):Point
		{
			var randomX:Number;
			var randomY:Number;
			
			if(Math.random() > .5)
			{
				randomX = width - width * Math.random();
				
				if(Math.random() > .5)
				{
					randomY = y;
				}
				else
				{
					randomY = height;
				}
			}
			else
			{
				if(Math.random() > .5)
				{
					randomX = x;
				}
				else
				{
					randomX = width;
				}
				
				randomY = height - height * Math.random();
			}
			
			return(new Point(randomX, randomY));
		}
		
		// similar to getRandomPointInRectangle but doesn't require a rectangle
		public static function getRandomPositionInside(x:Number, y:Number, width:Number, height:Number):Point
		{
			var randomX:Number = x + (Math.random() * (width - x));
			var randomY:Number = y + (Math.random() * (height - y));

			return(new Point(randomX, randomY));
		}
		
		public static function randomInRange(min:Number, max:Number):Number 
		{
			return Math.random()*(max-min +1)+min;
		}
		
		public static function randomInt(min:int, max:int):int 
		{
			return int( Math.random()*(max-min +1) + min );
		}
		
		public static function spatialDistance(spatial1:Spatial, spatial2:Spatial):Number
		{
			return(Math.sqrt(((spatial1.x - spatial2.x) * (spatial1.x - spatial2.x)) + ((spatial1.y - spatial2.y) * (spatial1.y - spatial2.y))));
		}
		
		public static function distSquaredPt (pt1:Point, pt2:Point):Number {
			
			var dx:Number = pt1.x - pt2.x;
			var dy:Number = pt1.y - pt2.y;
			return dx * dx + dy * dy
		}
		
		public static function distSquared (x1:Number,y1:Number,x2:Number,y2:Number):Number {
			
			var dx:Number = x1 - x2;
			var dy:Number = y1 - y2;
			return dx * dx + dy * dy;
		}
		
		public static function dist(x1:Number,y1:Number,x2:Number,y2:Number):Number {
			
			var dx:Number = x1 - x2;
			var dy:Number = y1 - y2;
			return Math.sqrt( dx * dx + dy * dy);
		}
		
		public static function distFromDelta(dx:Number, dy:Number):Number
		{
			return Math.sqrt( dx * dx + dy * dy);
		}
		
		public static function distPoint(p1:Point,p2:Point):Number {
			return dist(p1.x,p1.y,p2.x,p2.y);
		}
		
		/**
		 * Returns angle difference (in radians) between target and current position
		 * @param	targetX
		 * @param	targetY
		 * @param	x
		 * @param	y
		 * @return
		 */
		public static function radiansBetween (targetX:Number,targetY:Number,x:Number,y:Number):Number {
			
			var distX:Number = targetX - x;
			var distY:Number = targetY - y;
			var radian:Number = Math.atan( distY / distX )
			if ( distX >= 0 ) 
			{
				radian += Math.PI;
			}
			return radian;
		}
		
		
		public static function degreesBetweenPts (p1:Point,p2:Point):Number {
			return degreesBetween(p1.x,p1.y, p2.x, p2.y)
		}
		
		/**
		 * Returns angle difference (in degrees) between target and current position
		 * @param	targetX
		 * @param	targetY
		 * @param	x
		 * @param	y
		 * @return
		 */
		public static function degreesBetween (x1:Number, y1:Number, x2:Number, y2:Number):Number 
		{	
			var distX:Number = x1 - x2;
			var distY:Number = y1 - y2;
			var radians:Number = Math.atan2(distY, distX);
			var degree:Number = radians * 180 / Math.PI;
			
			return degree;
		}
		
		public static function radianToDegree (radian:Number):Number {
			
			return (180 * radian / Math.PI);
		}
		
		public static function degreeToRadian (degree:Number):Number {
			
			return (degree / 180 * Math.PI);
		}
		
		/**
		 * the following two functions interpret a zero value to mean
		 * the value is flexible; that is, it should be computed for best fit
		 */
		public static const ANY_NUMBER:uint = 0;
		
		/**
		 * Calculate how many rectangles of a given size will fit inside
		 * a frame of given size, when laid out in a <code>cols</code> by <code>rows</code> grid with <code>gutter</code>
		 * space between each column and row.
		 *
		 *	@param frameRect	the enclosing rectangle
		 *	@param cellRect		the dimension of each individual rectangle
		 *	@param cols			how many columns in the layout. A value of zero indicates that the number is flexible.
		 *	@param rows			how many rows in the layout. A value of zero indicates that the number is flexible.
		 *	@param gutter		how many pixels in between each column and row
		 *
		 *	@return	The maximum number of rectangles that will fit. A value of zero indicates infinite capacity.
		 */
		public static function getLayoutCapacity(frameRect:Rectangle, cellRect:Rectangle, cols:int, rows:int, gutter:Number):uint 
		{
			var capacity:uint = ANY_NUMBER;
			if ( rows + cols > ANY_NUMBER ) 						// must define row or column
			{
				var isHorizontal:Boolean = false;					// 0 == horizontal, 1 == vertical
				if ((ANY_NUMBER == cols) || (ANY_NUMBER == rows)) 	// flexible layout
				{		
					// calculate capacity of one visible page
					var colWidth:Number
					var rowHeight:Number;
					isHorizontal = (ANY_NUMBER == cols);
					if (isHorizontal) 			// horizontal orientation
					{		
						colWidth = cellRect.width + gutter;
						rowHeight = frameRect.height / rows;
					} 
					else 
					{							// vertical orientation
						colWidth = frameRect.width / cols;
						rowHeight = cellRect.height + gutter;
					}
					var visibleCols:int = Math.floor(frameRect.width / colWidth);
					var visibleRows:int = Math.floor(frameRect.height / rowHeight);
					
					// make some spares. Why? - bard
					/*
					if (isHorizontal) {
						visibleCols += rows;
					} else {
						visibleRows += cols;
					}
					*/
					capacity = visibleCols * visibleRows;
				} 
				else 												// finite grid
				{		
					capacity = cols * rows;
				}
			}
			return capacity;
		}
		
		/**
		 * Determines the size an individual item's rectangle must be to fit
		 * in a frame laid out in a <code>cols</code> by <code>rows</code> grid with <code>gutter</code>
		 * space between each column and row.
		 * 
		 * @param frameRect		the enclosing rectangle
		 * @param slotRect	a rectangle describing the dimensions of each item to be displayed
		 * @param cols			how many columns in the layout. A value of zero indicates that the number is flexible.
		 * @param rows			how many rows in the layout. A value of zero indicates that the number is flexible.
		 * @param gutter		how many pixels in between each column and row
		 * @return A rectangle sized to accommodate the specified layout
		 * 
		 */		
		public static function getLayoutCellRect(frameRect:Rectangle, slotRect:Rectangle, cols:int, rows:int, gutter:Number):Rectangle 
		{
			var aspectRatio:Number;
			
			// a 1x1 grid needs no gutter, so fit to frameRect
			if (1 == rows && 1 == cols) 	
			{	
				aspectRatio = frameRect.height / slotRect.height;
				if (slotRect.width * aspectRatio > frameRect.width) 	// need to go smaller?
				{	
					aspectRatio = frameRect.width / slotRect.width;
				}
				return new Rectangle(0, 0, slotRect.width * aspectRatio, slotRect.height * aspectRatio);
			}

			// if neither columns or rows have been specified as infinite (0), use rows and columns to determine max possible rectangle
			if( cols != 0 && rows != 0 )	
			{
				var scaleYRatio:Number = ((frameRect.height - (gutter * (rows - 1))) / rows)/slotRect.height;
				var scaleXRatio:Number = ((frameRect.width - (gutter * (cols - 1))) / cols)/slotRect.width;
				aspectRatio = Math.min( scaleXRatio, scaleYRatio );
				return new Rectangle(0, 0, slotRect.width * aspectRatio, slotRect.height * aspectRatio);
			}
										
			// if columns or rows has been undefined, value of 0, use given value (rows or columns) to determine max possible rectangle
			var cellHeight:Number = 0;
			var cellWidth:Number = 0;
			if ( cols == 0) 				// specified rows, numColumns flexible
			{			
				cellHeight = (frameRect.height - (gutter * (rows+1))) / rows;
				cellWidth = cellHeight * (slotRect.width / slotRect.height);
			} 
			else						 	// specified columns, numRows flexible
			{	
				cellWidth = (frameRect.width - (gutter * (cols+1))) / cols;
				cellHeight = cellWidth * (slotRect.height / slotRect.width);
			}
			return new Rectangle(0, 0, cellWidth, cellHeight);
		}
		
		/**
		 * Calculates the rectangles needed for a given number of items to fit 
		 * in a frame laid out in a <code>cols</code> by <code>rows</code> grid with <code>gutter</code>
		 * space between each column and row.
		 * 
		 * @param numItems		The number of items to lay out.
		 * @param frameRect		The enclosing rectangle.
		 * @param cellRect		The dimensions of each individual rectangle
		 * @param cols			
		 * @param rows			
		 * @param gutter
		 * @return 
		 * 
		 */		
		public static function getGridRects(numItems:int, frameRect:Rectangle, cellRect:Rectangle, cols:int, rows:int, gutter:Number, isHorizontal:Boolean = true):Vector.<Rectangle> 
		{
			var gridRects:Vector.<Rectangle>;
			if (isHorizontal) {				// stacked rows, numColumns flexible
				gridRects = calculateHorizontalGrid(numItems, frameRect, cellRect, cols, rows, gutter);
			} else {							// multiple columns, numRows flexible
				gridRects = calculateVerticalGrid(numItems, frameRect, cellRect, cols, rows, gutter);
			}
			return gridRects;
		}
		
		/**
		 * Calculates the rectangles needed for a given number of items to fit, condensing display when frame is not fully filled,
		 * in a frame laid out in a <code>cols</code> by <code>rows</code> grid with <code>gutter</code>
		 * space between each column and row.
		 * 
		 * @param numItems		The number of items to lay out.
		 * @param frameRect		The enclosing rectangle.
		 * @param cellRect		The dimensions of each individual rectangle
		 * @param cols			
		 * @param rows			
		 * @param gutter
		 * @return 
		 * 
		 */		
		public static function getGridRectsCondensed(numItems:int, frameRect:Rectangle, cellRect:Rectangle, cols:int, rows:int, gutter:Number = 0, isHorizontal:Boolean = true):Vector.<Rectangle> 
		{
			var gridRects:Vector.<Rectangle>;
			if (isHorizontal) {					// stacked rows, numColumns flexible
				gridRects = calculateHorizontalGridCondensed(numItems, frameRect, cellRect, cols, rows, gutter);
			} else {							// multiple columns, numRows flexible
				gridRects = calculateVerticalGridCondensed(numItems, frameRect, cellRect, cols, rows, gutter);	// TODO :: haven't made a condensed method for vertical orientation yet. - bard
			}
			return gridRects;
		}
		
		/**
		 * Returns a numeric code describing a layout's dimensions.
		 *
		 * @param	cols
		 * @param	rows
		 *
		 * @return	1 for horizontal, 2 for vertical, 3 for square, zero for failure
		 */
		/*
		private static function getLayoutOrientation(cols:int, rows:int):uint 
		{
			if (rows == cols) {
				return 3;		// square
			}
			if ((ANY_NUMBER == cols) || (cols > rows)) {
				return 1;		// horizontal
			}
			if ((ANY_NUMBER == rows) || (rows > cols)) {
				return 2;		// vertical
			}
			return 0;			// zero indicates an unexpected result
		}
		*/
		
		private static function calculateHorizontalGrid(numSlots:int, frameRect:Rectangle, cellRect:Rectangle, cols:int, rows:int, gutter:Number = 0):Vector.<Rectangle>
		{
			var frameCapacity:uint = getLayoutCapacity(frameRect,cellRect, cols, rows, gutter);
			var gridRects:Vector.<Rectangle> = new Vector.<Rectangle>();
			var colWidth:Number = cellRect.width + gutter;
			var rowHeight:Number = cellRect.height + gutter;
			var visibleCols:int = Math.floor(frameRect.width / colWidth);	// num of cols that will fit within frame
			var layoutRows:int = Math.min(rows, Math.ceil(numSlots / visibleCols));
			var layoutCols:int = (numSlots < frameCapacity) ? visibleCols : Math.ceil(numSlots / layoutRows); //tightest packing not wanted when there's so much room
			
			var itemRect:Rectangle;
			var top:Number;
			if (layoutRows < 2)
			{
				// only one row? center it vertically in frame
				top = (frameRect.height - cellRect.height) / 2;
			}
			
			for (var row:int = 0; row < layoutRows; row++) 
			{
				// only one row? center it vertically in frame
				if (layoutRows >= 2)
				{		
					top = frameRect.top + row * rowHeight;
				}
				
				for (var col:int = 0; col < layoutCols; col++) 
				{
					if (numSlots--) 
					{
						itemRect = cellRect.clone();
						itemRect.offset( frameRect.left + col * colWidth, top );
						gridRects.push(itemRect);
					} else {
						break;
					}
				}
			}
			return gridRects;
		}
		
		private static function calculateHorizontalGridCondensed(numSlots:int, frameRect:Rectangle, cellRect:Rectangle, cols:int, rows:int, gutter:Number = 0):Vector.<Rectangle>
		{
			var gridRects:Vector.<Rectangle> = new Vector.<Rectangle>();
			var colWidth:Number = cellRect.width + gutter;
			var rowHeight:Number = cellRect.height + gutter;
			
			var maxVisibleCols:int = Math.floor( frameRect.width/colWidth );
			var rect:Rectangle;
			var numCols:int;
			var numRows:int;
			var currentRow:int;
			var currentCol:int;
			var rowX:int;
			var rowY:int;
			var i:int;
			var startX:Number = frameRect.x;
			
			// make a single column
			if( numSlots <= rows )
			{
				rowX =  frameRect.x + ( frameRect.width - numSlots * colWidth + gutter ) * .5;
				rowY = frameRect.y + ( frameRect.height - rowHeight ) * .5;
				
				for (i = 0; i < numSlots; i++) 
				{
					rect = cellRect.clone();
					rect.x = rowX + i * colWidth
					rect.y = rowY;
					gridRects.push( rect );
				}
			}
			else if ( numSlots <= ( rows * maxVisibleCols) )
			{
				// adjust row length to fill space
				numRows = Math.ceil( numSlots/maxVisibleCols );
				numCols = Math.ceil( numSlots/numRows );
				rowX =  frameRect.x + ( frameRect.width - numCols * colWidth ) * .5
				rowY = frameRect.y + ( frameRect.height - numRows * rowHeight ) * .5
				currentRow = 0;
				currentCol = 0;
				
				for (i = 0; i < numSlots; i++) 
				{
					rect = cellRect.clone();
					rect.x = rowX + currentCol * colWidth;
					rect.y = rowY + currentRow * rowHeight;
					gridRects.push( rect );
					
					currentRow++;
					if( currentRow == numRows )
					{
						currentRow = 0;
						currentCol++;
					}
				}
			}
			else
			{
				numRows = rows;
				numCols = cols;
				rowY = frameRect.y + ( frameRect.height - numRows * rowHeight ) * .5
				currentRow = 0;
				currentCol = 0;
				
				for (i = 0; i < numSlots; i++) 
				{
					rect = cellRect.clone();
					rect.x = frameRect.x + currentCol * colWidth;
					rect.y = rowY + currentRow * rowHeight;
					gridRects.push( rect );
					
					currentRow++;
					if( currentRow == numRows )
					{
						currentRow = 0;
						currentCol++;
					}
				}
			}
			return gridRects;
		}
		
		private static function calculateVerticalGrid(numSlots:int, frameRect:Rectangle, cellRect:Rectangle, cols:int, rows:int, gutter:Number = 0):Vector.<Rectangle>
		{
			var frameCapacity:uint = getLayoutCapacity(frameRect, cellRect, cols, rows, gutter);
			var gridRects:Vector.<Rectangle> = new Vector.<Rectangle>();
			var colWidth:Number = cellRect.width + gutter;
			var rowHeight:Number = cellRect.height + gutter;
			var visibleRows:int = Math.floor(frameRect.height / rowHeight);	// num of rows that will fit within frame
			var layoutCols:int = Math.min(cols, Math.ceil(numSlots / visibleRows));
			var layoutRows:int = (numSlots < frameCapacity) ? visibleRows : Math.ceil(numSlots / layoutCols); //tightest packing not wanted when there's so much room
			
			var slotRect:Rectangle;
			var colX:Number;
			if (layoutCols < 2) 		// only one col? center it horizontally in frame
			{		
				colX = (frameRect.width - cellRect.width) / 2;
			}
			
			for (var col:int = 0; col < layoutCols; col++) 
			{
				if (layoutCols >= 2)
				{		
					colX = frameRect.left + col * colWidth;
				}
				
				for (var row:int = 0; row < layoutRows; row++) 
				{
					if (numSlots--) 
					{
						slotRect = cellRect.clone();
						slotRect.x = colX;
						slotRect.y = frameRect.y + gutter + row * rowHeight;
						gridRects.push(slotRect);
					} else {
						break;
					}
				}
			}
			return gridRects;
		}
		
		private static function calculateVerticalGridCondensed(numSlots:int, frameRect:Rectangle, cellRect:Rectangle, cols:int, rows:int, gutter:Number = 0):Vector.<Rectangle>
		{
			var gridRects:Vector.<Rectangle> = new Vector.<Rectangle>();
			var cellHeight:Number = cellRect.height + gutter;
			var cellWidth:Number = cellRect.width + gutter;
			
			var maxVisibleRows:int = Math.floor( frameRect.height/cellHeight );
			var rect:Rectangle;
			var numCols:int;
			var numRows:int;
			var currentRow:int;
			var currentCol:int;
			var colX:int;
			var colY:int;
			var i:int;
			var startY:Number = frameRect.y;
			
			// make a single row
			if( numSlots <= cols )
			{
				colX = frameRect.x + ( frameRect.width - cellWidth + gutter ) * .5; // 
				colY = frameRect.y + ( frameRect.height - numSlots * cellHeight ) * .5;
				
				for (i = 0; i < numSlots; i++) 
				{
					rect = cellRect.clone();
					rect.x = colX;
					rect.y = colY + i * cellHeight;
					gridRects.push( rect );
				}
			}
			else if ( numSlots <= ( cols * maxVisibleRows) )
			{
				// adjust col length to fill space
				numCols = Math.ceil( numSlots/maxVisibleRows );
				numRows = Math.ceil( numSlots/numCols )
				colX = frameRect.x + ( frameRect.width - (numCols * cellWidth + gutter) ) * .5;
				colY = frameRect.y + ( frameRect.height - numRows * cellHeight ) * .5
				currentRow = 0;
				currentCol = 0;
				
				for (i = 0; i < numSlots; i++) 
				{
					rect = cellRect.clone();
					rect.x = gutter + colX + currentCol * cellWidth
					rect.y = gutter + colY + currentRow * cellHeight
					gridRects.push( rect );
					
					currentRow++;
					if( currentRow == numRows )
					{
						currentRow = 0;
						currentCol++;
					}
				}
			}
			else
			{
				numRows = rows;
				numCols = cols;
				colX = frameRect.x + ( frameRect.width - numCols * cellWidth ) * .5
				currentRow = 0;
				currentCol = 0;
				
				for (i = 0; i < numSlots; i++) 
				{
					rect = cellRect.clone();
					rect.x = gutter + currentCol * cellWidth;
					rect.y = gutter + currentRow * cellHeight;
					gridRects.push( rect );
					
					currentRow++;
					if( currentRow == numRows )
					{
						currentRow = 0;
						currentCol++;
					}
				}
			}
			return gridRects;
		}
		
		
		
		public static function getPointOffsetFromRotation(originX:Number, originY:Number, rotation:Number, offsetX:Number, offsetY:Number):Point
		{
			rotation *= (Math.PI / 180);
			
			var cos:Number = Math.cos(rotation);
			var sin:Number = Math.sin(rotation);
			var offsetPosition:Point = new Point();
			
			offsetPosition.x = cos * offsetX - sin * offsetY + originX;
			offsetPosition.y = sin * offsetX + cos * offsetY + originY;
			
			return(offsetPosition);
		}
		
		public static function radiansBetweenPts(goal:Point, targ:Point):Number
		{
			return radiansBetween(goal.x,goal.y,targ.x,targ.y);
		}
		
		
		/**
		 * Returns intersect point between two lines, line AB &amp; line CD respectively 
		 * @param a
		 * @param b
		 * @param c
		 * @param d
		 * @return Point of intersect or null if line do not intersect.
		 */
		public static function lineIntersection(a:Point, b:Point, c:Point, d:Point):Point
		{
			var distAB:Number, cos:Number, sin:Number, newX:Number, ABpos:Number;
			if ((a.x == b.x && a.y == b.y) || (c.x == d.x && c.y == d.y)) return null;
			
			if ( a == c || a == d || b == c || b == d ) return null;
			
			b = b.clone();
			c = c.clone();
			d = d.clone();
			
			b.offset( -a.x, -a.y);
			c.offset( -a.x, -a.y);
			d.offset( -a.x, -a.y);
			// a is now considered to be (0,0)
			
			distAB = b.length;
			cos = b.x / distAB;
			sin = b.y / distAB;
			
			c = new Point(c.x * cos + c.y * sin, c.y * cos - c.x * sin);
			d = new Point(d.x * cos + d.y * sin, d.y * cos - d.x * sin);
			
			if ((c.y < 0 && d.y < 0) || (c.y >= 0 && d.y >= 0)) return null;
			
			ABpos = d.x + (c.x - d.x) * d.y / (d.y - c.y); // what.
			if (ABpos < 0 || ABpos > distAB) return null;
			
			return new Point(a.x + ABpos * cos, a.y + ABpos * sin);			
		}
		
		/**
		 * Determiens if two lines intersect, line AB &amp; line CD respectively 
		 * @param a
		 * @param b
		 * @param c
		 * @param d
		 * @return Point of intersect or null if line do not intersect.
		 */
		/*
		public static function lineCollision(a:Point, b:Point, c:Point, d:Point):Boolean
		{
			var distAB:Number
			var cos:Number;
			var sin:Number;
			var newX:Number;
			var ABpos:Number;
			
			if ((a.x == b.x && a.y == b.y) || (c.x == d.x && c.y == d.y)) return false;
			
			if ( a == c || a == d || b == c || b == d ) return false;
			
			b = b.clone();
			c = c.clone();
			d = d.clone();
			
			b.offset( -a.x, -a.y);
			c.offset( -a.x, -a.y);
			d.offset( -a.x, -a.y);
			// a is now considered to be (0,0)
			
			distAB = b.length;
			cos = b.x / distAB;
			sin = b.y / distAB;
			
			c = new Point(c.x * cos + c.y * sin, c.y * cos - c.x * sin);
			d = new Point(d.x * cos + d.y * sin, d.y * cos - d.x * sin);
			
			if ((c.y < 0 && d.y < 0) || (c.y >= 0 && d.y >= 0)) return false;
			
			ABpos = d.x + (c.x - d.x) * d.y / (d.y - c.y); // what.
			if (ABpos < 0 || ABpos > distAB) return false;
			
			return true;			
		}
		*/
		
		/*
		public static function lineCollision(p1:Point, p2:Point, p3:Point, p4:Point):Boolean 
		{
			var x1:Number = p1.x, x2:Number = p2.x, x3:Number = p3.x, x4:Number = p4.x;
			var y1:Number = p1.y, y2:Number = p2.y, y3:Number = p3.y, y4:Number = p4.y;
			var z1:Number= (x1 -x2), z2:Number = (x3 - x4), z3:Number = (y1 - y2), z4:Number = (y3 - y4);
			var d:Number = z1 * z4 - z3 * z2;
			
			// If d is zero, there is no intersection
			if (d == 0) return null;
			
			// Get the x and y
			var pre:Number = (x1*y2 - y1*x2), post:Number = (x3*y4 - y3*x4);
			var x:Number = ( pre * z2 - z1 * post ) / d;
			var y:Number = ( pre * z4 - z3 * post ) / d;
			
			// Check if the x and y coordinates are within both lines
			if ( x < Math.min(x1, x2) || x > Math.max(x1, x2) ||
				x < Math.min(x3, x4) || x > Math.max(x3, x4) ) return null;
			if ( y < Math.min(y1, y2) || y > Math.max(y1, y2) ||
				y < Math.min(y3, y4) || y > Math.max(y3, y4) ) return null;
			
			// Return the point of intersection
			return new Point(x, y);
		}
		*/
		
		//---------------------------------------------------------------
		//Checks for intersection of Segment if as_seg is true.
		//Checks for intersection of Line if as_seg is false.
		//Return intersection of Segment AB and Segment EF as a Point
		//Return null if there is no intersection
		//---------------------------------------------------------------
		public static function lineIntersectLine(A:Point,B:Point,E:Point,F:Point,as_seg:Boolean=true):Boolean 
		{
			var ip:Point;
			var a1:Number;
			var a2:Number;
			var b1:Number;
			var b2:Number;
			var c1:Number;
			var c2:Number;
			
			a1= B.y-A.y;
			b1= A.x-B.x;
			c1= B.x*A.y - A.x*B.y;
			a2= F.y-E.y;
			b2= E.x-F.x;
			c2= F.x*E.y - E.x*F.y;
			
			var denom:Number=a1*b2 - a2*b1;
			if (denom == 0) {
				return false;
			}
			ip=new Point();
			ip.x=(b1*c2 - b2*c1)/denom;
			ip.y=(a2*c1 - a1*c2)/denom;
			
			//---------------------------------------------------
			//Do checks to see if intersection to endpoints
			//distance is longer than actual Segments.
			//Return null if it is with any.
			//---------------------------------------------------
			if(as_seg){
				if(Math.pow(ip.x - B.x, 2) + Math.pow(ip.y - B.y, 2) > Math.pow(A.x - B.x, 2) + Math.pow(A.y - B.y, 2))
				{
					return false;
				}
				if(Math.pow(ip.x - A.x, 2) + Math.pow(ip.y - A.y, 2) > Math.pow(A.x - B.x, 2) + Math.pow(A.y - B.y, 2))
				{
					return false;
				}
				
				if(Math.pow(ip.x - F.x, 2) + Math.pow(ip.y - F.y, 2) > Math.pow(E.x - F.x, 2) + Math.pow(E.y - F.y, 2))
				{
					return false;
				}
				if(Math.pow(ip.x - E.x, 2) + Math.pow(ip.y - E.y, 2) > Math.pow(E.x - F.x, 2) + Math.pow(E.y - F.y, 2))
				{
					return false;
				}
			}
			return true;
			//return ip;
		}
		
		/**
		 * Determines if a line is intersecting a rectangle.
		 * The bounds of the line is passed, with a flag determining one of 2 possible slopes. 
		 * @param rect
		 * @param lineRect
		 * @param topLeftToBotRight
		 * @return 
		 * 
		 */
		public static function lineRectCollision( rect:Rectangle, lineRect:Rectangle, topLeftToBotRight:Boolean = true ):Boolean
		{
			// do basic rect bounds check first
			if( !rect.intersects( lineRect ) )	return false;
						
			// break rect into lines, determine line points, test lines against each other
			var a:Point;
			var b:Point;
			if( topLeftToBotRight )
			{
				a = new Point( lineRect.x, lineRect.y );
				b = new Point( lineRect.x + lineRect.width, lineRect.y + lineRect.height ); 
			}
			else
			{
				a = new Point( lineRect.x, lineRect.y + lineRect.height );
				b = new Point( lineRect.x + lineRect.width, lineRect.y ); 
			}
			
			var c:Point = new Point( rect.x, rect.y );	// top left
			var d:Point = new Point( rect.x + rect.width, rect.y);	//top right
			var e:Point = new Point( rect.x, rect.y + rect.height);	// bottom left
			
			if( !lineIntersectLine( a, b, c, d ) )
			{
				if( !lineIntersectLine( a, b, c, e ) )
				{
					c.x = d.x;
					c.y = e.y;
					if( !lineIntersectLine( a, b, d, c ) )
					{
						if( !lineIntersectLine( a, b, e, c ) )
						{
							return false;
						}
					}
				}
			}
			return true;
		}
	}
}