package game.util
{
	import flash.geom.Rectangle;
	
	/**
	 * @author Drew Martin
	 */
	public class GridAlignment
	{
		/**
		 * These constants are used for DisplayObject distribution within the bounds of a Rectangle.
		 */
		public static const RIGHT_AND_DOWN:String 	= "right_and_down";
		public static const RIGHT_AND_UP:String 	= "right_and_up";
		public static const LEFT_AND_DOWN:String 	= "left_and_down";
		public static const LEFT_AND_UP:String 		= "left_and_up";
		public static const DOWN_AND_RIGHT:String 	= "down_and_right";
		public static const DOWN_AND_LEFT:String 	= "down_and_left";
		public static const UP_AND_RIGHT:String 	= "up_and_right";
		public static const UP_AND_LEFT:String 		= "up_and_left";
		
		/**
		 * Distributes an Array of DisplayObjects vertically, starting at <code>rectangle.x</code> and
		 * <code>rectangle.y</code> and moving down. <code>rectangle.width</code> and <code>rectangle.height</code>
		 * are considered to be the dimensions of each cell unless <code>columns > 1</code>, in which case the cell
		 * width will be recalculated and the cell height will be scaled accordingly to match.
		 * 
		 * @param displays An Array of DisplayObjects to distribute.
		 * @param rectangle A containing Rectangle whose (x, y) determine the starting point and whose width/height
		 * determine the pre-calculated cell bounds.
		 * @param columns The number of columns to divide the horizontal space into.
		 * @param spacingX The horizontal spacing between cells.
		 * @param spacingY The vertical spacing between cells.
		 * @param alignment A DisplayAlignment enumeration for DisplayObject positioning in the cell.
		 * @param aligner A Function for positioning. The DisplayAlignment functions stretchAndAlign(), fillAndAlign(), fitAndAlign()
		 * @param distribution A DisplayAlignment enumeration for DisplayObject distribution in the containing Rectangle.
		 */
		public static function distributeVertically(displays:Array, grid:Rectangle, columns:int = 1, spacingX:Number = 0, spacingY:Number = 0, alignment:String = DisplayAlignment.MID_X_MID_Y, aligner:Function = null, distribution:String = RIGHT_AND_DOWN):void
		{
			var length:uint = displays.length;
			
			if(columns > length) columns 	= length;
			else if(columns < 1) columns 	= 1;
			var rows:int 					= Math.ceil(length / columns);
			
			var width:Number 	= GridAlignment.getCellDimension(grid.width, columns, spacingX);
			var height:Number 	= grid.height * (width / grid.width);
			
			var cell:Rectangle = new Rectangle(0, 0, width, height);
			
			GridAlignment.distribute(displays, cell, grid, columns, rows, spacingX, spacingY, alignment, aligner, distribution);
		}
		
		public static function distributeVerticallyScaled(displays:Array, grid:Rectangle, columns:int = 1, spacingX:Number = 0, spacingY:Number = 0, alignment:String = DisplayAlignment.MID_X_MID_Y, aligner:Function = null, distribution:String = RIGHT_AND_DOWN):void
		{
			var length:uint = displays.length;
			
			if(columns > length) columns 	= length;
			else if(columns < 1) columns 	= 1;
			var rows:int 					= Math.ceil(length / columns);
			
			var width:Number 	= GridAlignment.getCellDimension(grid.width, columns, spacingX);
			var height:Number 	= grid.height / rows;
			
			var cell:Rectangle = new Rectangle(0, 0, width, height);
			
			GridAlignment.distribute(displays, cell, grid, columns, rows, spacingX, spacingY, alignment, aligner, distribution);
		}
		
		/**
		 * Distributes an Array of DisplayObjects horizontally, starting at <code>rectangle.x</code> and
		 * <code>rectangle.y</code> and moving right. <code>rectangle.width</code> and <code>rectangle.height</code>
		 * are considered to be the dimensions of each cell unless <code>rows > 1</code>, in which case the cell
		 * height will be recalculated and the cell width will be scaled accordingly to match.
		 * 
		 * @param displays An Array of DisplayObjects to distribute.
		 * @param rectangle A containing Rectangle whose (x, y) determine the starting point and whose width/height
		 * determine the pre-calculated cell bounds.
		 * @param rows The number of rows to divide the vertical space into.
		 * @param spacingX The horizontal spacing between cells.
		 * @param spacingY The vertical spacing between cells.
		 * @param alignment A DisplayAlignment enumeration for DisplayObject positioning in the cell Rectangle.
		 * @param aligner A Function for positioning. The DisplayAlignment functions stretchAndAlign(), fillAndAlign(), fitAndAlign() are valid.
		 * @param distribution A DisplayAlignment enumeration for DisplayObject distribution in the containing Rectangle.
		 */
		public static function distributeHorizontally(displays:Array, grid:Rectangle, rows:int = 1, spacingX:Number = 0, spacingY:Number = 0, alignment:String = DisplayAlignment.MID_X_MID_Y, aligner:Function = null, distribution:String = RIGHT_AND_DOWN):void
		{
			var length:uint = displays.length;
			
			if(rows > length) rows 	= length;
			else if(rows < 1) rows 	= 1;
			var columns:int 		= Math.ceil(length / rows);
			
			var height:Number 	= GridAlignment.getCellDimension(grid.height, rows, spacingY);
			var width:Number	= grid.width * (height / grid.height);
			
			var cell:Rectangle = new Rectangle(0, 0, width, height);
			
			GridAlignment.distribute(displays, cell, grid, columns, rows, spacingX, spacingY, alignment, aligner, distribution);
		}
		
		public static function distributeHorizontallyScaled(displays:Array, grid:Rectangle, rows:int = 1, spacingX:Number = 0, spacingY:Number = 0, alignment:String = DisplayAlignment.MID_X_MID_Y, aligner:Function = null, distribution:String = RIGHT_AND_DOWN):void
		{
			var length:uint = displays.length;
			
			if(rows > length) rows 	= length;
			else if(rows < 1) rows 	= 1;
			var columns:int 		= Math.ceil(length / rows);
			
			var height:Number 	= GridAlignment.getCellDimension(grid.height, rows, spacingY);
			var width:Number	= grid.width / columns;
			
			var cell:Rectangle = new Rectangle(0, 0, width, height);
			
			GridAlignment.distribute(displays, cell, grid, columns, rows, spacingX, spacingY, alignment, aligner, distribution);
		}
		
		/**
		 * Distributes an Array of DisplayObjects within a given <code>rectangle</code> automatically by attempting to calculate
		 * a grid with as close to an even number of columns and rows as possible. Then based off of these columns and rows,
		 * it calculates the Rectangle of a cell and positions each DisplayObject.
		 * 
		 * @param displays An Array of DisplayObjects to distribute.
		 * @param rectangle A containing Rectangle whose dimensions determine the bounds of the cells.
		 * @param spacingX The horizontal spacing between cells.
		 * @param spacingY The vertical spacing between cells.
		 * @param alignment A value determining how the DisplayObject should be positioned in the cell.
		 * @param aligner A Function for positioning. The DisplayAlignment functions stretchAndAlign(), fillAndAlign(), fitAndAlign() are valid.
		 * @param distribution A DisplayAlignment enumeration for DisplayObject distribution in the containing Rectangle.
		 */
		public static function distributeScaledAuto(displays:Array, grid:Rectangle, spacingX:Number = 0, spacingY:Number = 0, alignment:String = DisplayAlignment.MID_X_MID_Y, aligner:Function = null, distribution:String = RIGHT_AND_DOWN):void
		{
			var dimension:Number 	= Math.sqrt(displays.length);
			var columns:uint 		= Math.ceil(dimension);
			var rows:uint 			= Math.round(dimension);
			
			var cell:Rectangle = GridAlignment.getCell(grid, columns, rows, spacingX, spacingY);
			
			GridAlignment.distribute(displays, cell, grid, columns, rows, spacingX, spacingY, alignment, aligner, distribution);
		}
		
		/**
		 * Distributes an Array of DisplayObjects within a given <code>rectangle</code> by dividing the <code>rectangle</code>'s
		 * space into cells calculated by <code>columns</code>, <code>rows</code>, <code>spacingX</code>, and
		 * <code>spacingY</code>. DisplayObjects are then distributed and sized to fit these cells accordingly.
		 * 
		 * @param displays An Array of DisplayObjects to distribute.
		 * @param rectangle A containing Rectangle whose dimensions determine the bounds of the cells.
		 * @param columns The number of columns to divide the containing Rectangle into.
		 * @param rows The number of rows to divide the containing Rectangle into.
		 * @param spacingX The horizontal spacing between cells.
		 * @param spacingY The vertical spacing between cells.
		 * @param alignment A value determining how the DisplayObject should be positioned in the cell.
		 * @param aligner A Function for positioning. The DisplayAlignment functions stretchAndAlign(), fillAndAlign(), fitAndAlign() are valid.
		 * @param distribution A DisplayAlignment enumeration for DisplayObject distribution in the containing Rectangle.
		 */
		public static function distributeScaled(displays:Array, grid:Rectangle, columns:int, rows:int, spacingX:Number = 0, spacingY:Number = 0, alignment:String = DisplayAlignment.MID_X_MID_Y, aligner:Function = null, distribution:String = RIGHT_AND_DOWN):void
		{
			var cell:Rectangle = GridAlignment.getCell(grid, columns, rows, spacingX, spacingY);
			
			GridAlignment.distribute(displays, cell, grid, columns, rows, spacingX, spacingY, alignment, aligner, distribution);
		}
		
		public static function distribute(displays:Array, cell:Rectangle, grid:Rectangle, columns:int, rows:int, spacingX:Number = 0, spacingY:Number = 0, cellAlign:String = DisplayAlignment.MID_X_MID_Y, aligner:Function = null, distribution:String = RIGHT_AND_DOWN):void
		{
			if(aligner == null) aligner = DisplayAlignment.fitAndAlign;
			
			var x:int;
			var y:int;
			var startX:Number 	= grid.x;
			var startY:Number 	= grid.y;
			var offsetX:Number 	= cell.width + spacingX;
			var offsetY:Number 	= cell.height + spacingY;
			var length:uint 	= displays.length;
			var index:int 		= -1;
			
			switch(distribution)
			{
				case GridAlignment.RIGHT_AND_DOWN:
					for(y = 0; y < rows; ++y)
					{
						cell.y = startY + y * offsetY;
						
						for(x = 0; x < columns; ++x)
						{
							cell.x = startX + x * offsetX;
							
							//trace(cell);
							
							if(++index > length - 1) return;
							
							aligner(displays[index], cell, null, cellAlign);
							
							//trace(displays[index].x, displays[index].y);
						}
					}
					break;
				
				case GridAlignment.RIGHT_AND_UP:
					for(y = rows - 1; y > -1; --y)
					{
						cell.y = startY + y * offsetY;
						
						for(x = 0; x < columns; ++x)
						{
							cell.x = startX + x * offsetX;
							
							if(++index > length - 1) return;
							
							aligner(displays[index], cell, null, cellAlign);
						}
					}
					break;
				
				case GridAlignment.LEFT_AND_DOWN:
					for(y = 0; y < rows; ++y)
					{
						cell.y = startY + y * offsetY;
						
						for(x = columns - 1; x > -1; --x)
						{
							cell.x = startX + x * offsetX;
							
							if(++index > length - 1) return;
							
							aligner(displays[index], cell, null, cellAlign);
						}
					}
					break;
				
				case GridAlignment.LEFT_AND_UP:
					for(y = rows - 1; y > -1; --y)
					{
						cell.y = startY + y * offsetY;
						
						for(x = columns - 1; x > -1; --x)
						{
							cell.x = startX + x * offsetX;
							
							if(++index > length - 1) return;
							
							aligner(displays[index], cell, null, cellAlign);
						}
					}
					break;
				
				case GridAlignment.DOWN_AND_RIGHT:
					for(x = 0; x < columns; ++x)
					{
						cell.x = startX + x * offsetX;
						
						for(y = 0; y < rows; ++y)
						{
							cell.y = startY + y * offsetY;
							
							if(++index > length - 1) return;
							
							aligner(displays[index], cell, null, cellAlign);
						}
					}
					break;
				
				case GridAlignment.DOWN_AND_LEFT:
					for(x = columns - 1; x > -1; --x)
					{
						cell.x =startX + x * offsetX;
						
						for(y = 0; y < rows; ++y)
						{
							cell.y = startY + y * offsetY;
							
							if(++index > length - 1) return;
							
							aligner(displays[index], cell, null, cellAlign);
						}
					}
					break;
				
				case GridAlignment.UP_AND_RIGHT:
					for(x = 0; x < columns; ++x)
					{
						cell.x = startX + x * offsetX;
						
						for(y = rows - 1; y > -1; --y)
						{
							cell.y = startY + y * offsetY;
							
							if(++index > length - 1) return;
							
							aligner(displays[index], cell, null, cellAlign);
						}
					}
					break;
				
				case GridAlignment.UP_AND_LEFT:
					for(x = columns - 1; x > -1; --x)
					{
						cell.x = startX + x * offsetX;
						
						for(y = rows - 1; y > -1; --y)
						{
							cell.y = startY + y * offsetY;
							
							if(++index > displays.length - 1) return;
							
							aligner(displays[index], cell, null, cellAlign);
						}	
					}
					break;
			}
		}
		
		public static function getCellAt(x:int, y:int, grid:Rectangle, columns:int, rows:int, spacingX:Number = 0, spacingY:Number = 0):Rectangle
		{
			var cell:Rectangle 	= GridAlignment.getCell(grid, columns, rows, spacingX, spacingY);
			cell.x 				= grid.left + x * (cell.width + spacingX);
			cell.y 				= grid.top + y * (cell.height + spacingY);
			return cell;
		}
		
		public static function getCell(grid:Rectangle, columns:int, rows:int, spacingX:Number = 0, spacingY:Number = 0):Rectangle
		{
			var width:Number 	= GridAlignment.getCellDimension(grid.width, columns, spacingX);
			var height:Number 	= GridAlignment.getCellDimension(grid.height, rows, spacingY);
			return new Rectangle(0, 0, width, height);
		}
		
		public static function getCellDimension(dimension:Number, numCells:uint, spacing:Number = 0):Number
		{
			dimension -= spacing * (numCells - 1);
			dimension /= numCells;
			return dimension;
		}
		
		public static function getCells(grid:Rectangle, columns:int, rows:int, spacingX:Number = 0, spacingY:Number = 0):Vector.<Rectangle>
		{
			var cells:Vector.<Rectangle> 	= new Vector.<Rectangle>();
			var cloner:Rectangle 			= GridAlignment.getCell(grid, columns, rows, spacingX, spacingY);
			
			var y:int 			= -1;
			var index:int 		= -1;
			var numCells:uint 	= columns * rows;
			
			while(++index < numCells)
			{	
				var x:int 	= index % columns;
				if(x == 0) 	++y;
				
				var cell:Rectangle 	= cloner.clone();
				cell.x 				= grid.x + x * (cell.width + spacingX);
				cell.y 				= grid.y + y * (cell.height + spacingY);
				
				cells.push(cell);
			}
			
			return cells;
		}
	}
}