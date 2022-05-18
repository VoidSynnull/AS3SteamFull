package game.util
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	
	import engine.data.display.SharedBitmap;
	import engine.data.display.SharedBitmapData;
	
	/**
	 * Author: Drew Martin
	 * 
	 * BitmapUtils is a simple, lightweight way to work with Bitmaps and BitmapData.
	 */
	public class BitmapUtils
	{
		/**
		 * Creates BitmapData from the <code>display</code> DisplayObject. The <code>quality</code> gets multiplied
		 * with the <code>bounds</code> to create larger, more detailed BitmapData. You can optionally set the
		 * <code>bounds</code> to only draw a certain portion of the <code>display</code>.
		 */
		public static function createBitmapData(display:DisplayObject, quality:Number = 1, bounds:Rectangle = null, transparent:Boolean = true, fillColor:uint = 0):SharedBitmapData
		{
			if(!bounds) bounds = display.getBounds(display);
			
			return BitmapUtils.getBitmapData(display, bounds, new Matrix(), 0, 0, quality, transparent, fillColor);
		}
		
		/**
		 * Creates a Bitmap from the <code>display</code> DisplayObject. The <code>quality</code> gets multiplied
		 * with the <code>bounds</code> to create larger, more detailed BitmapData. The Bitmap's <code>scaleX</code>
		 * and <code>scaleY</code> get divided by the <code>quality</code> to compensate for the <code>quality</code> of
		 * the BitmapData. You can optionally set the <code>bounds</code> to only draw a certain portion of the
		 * <code>display</code>.
		 */
		public static function createBitmap(display:DisplayObject, quality:Number = 1, bounds:Rectangle = null, transparent:Boolean = true, fillColor:uint = 0, data:BitmapData = null):SharedBitmap
		{
			if(!bounds) bounds = display.getBounds(display.parent);
			
			if(!data) data 			= BitmapUtils.getBitmapData(display, bounds, display.transform.matrix, display.x, display.y, quality, transparent, fillColor);
			var bitmap:SharedBitmap = BitmapUtils.getBitmap(data, bounds.x, bounds.y, quality);
			
			return bitmap;
		}
		
		/**
		 * Creates a Bitmap wrapped in a Sprite from the <code>display</code> DisplayObject. This maintains the original
		 * <code>display</code>'s registration point. The <code>quality</code> gets multiplied with the <code>bounds</code> to
		 * create larger, more detailed BitmapData. The Bitmap's <code>scaleX</code> and <code>scaleY</code> get divided by
		 * the <code>quality</code> to compensate for the <code>quality</code> of the BitmapData. You can optionally set the
		 * <code>bounds</code> to only draw a certain portion of the <code>display</code>.
		 */
		public static function createBitmapSprite(display:DisplayObject, quality:Number = 1, bounds:Rectangle = null, transparent:Boolean = true, fillColor:uint = 0, data:BitmapData = null):Sprite
		{
			if(!bounds) bounds = display.getBounds(display);
			
			if(!data) data 		= BitmapUtils.getBitmapData(display, bounds, new Matrix(), 0, 0, quality, transparent, fillColor);
			var bitmap:Bitmap 	= BitmapUtils.getBitmap(data, bounds.x, bounds.y, quality);
			
			var sprite:Sprite 	= new Sprite();
			sprite.transform 	= display.transform;
			sprite.mouseEnabled = false;
			sprite.addChild(bitmap);
			
			return sprite;
		}
		
		/**
		 * Creates multiple Bitmaps wrapped in a Sprite from the <code>display</code> DisplayObject. This "tiles" the
		 * <code>display</code>, creating multiple smaller Bitmaps/BitmapDatas in order to reduce excessive memory cunsumption
		 * from larger bitmapped DisplayObjects. If a portion of the <code>display</code> is empty when drawn, that BitmapData
		 * is <code>dispose()</code>'d of to free memory. The <code>tileWidth</code> and <code>tileHeight</code> determine how
		 * large each Bitmap/BitmapData "tile" is. The <code>quality</code> gets multiplied with the <code>bounds</code> to
		 * create larger, more detailed BitmapData. The Bitmap's <code>scaleX</code> and <code>scaleY</code> get divided by
		 * the <code>quality</code> to compensate for the <code>quality</code> of the BitmapData. You can optionally set the
		 * <code>bounds</code> to only draw a certain portion of the <code>display</code>.
		 */
		public static function createBitmapSpriteTiled(display:DisplayObject, tileWidth:uint, tileHeight:uint, quality:Number = 1, bounds:Rectangle = null, transparent:Boolean = true, fillColor:uint = 0, overlap:uint = 0):Sprite
		{
			if(!bounds) bounds = display.getBounds(display);
			
			var sprite:Sprite 	= new Sprite();
			sprite.mouseEnabled = false;
			
			//tileWidth and tileHeight should be multiples of 2 (256 x 256, 512 x 512, etc.) for memory / performance reasons.
			var tileBounds:Rectangle 	= new Rectangle(0, 0, tileWidth, tileHeight);
			var numTilesX:uint 			= Math.ceil(bounds.width / (tileWidth - overlap));
			var numTilesY:uint 			= Math.ceil(bounds.height / (tileHeight - overlap));
			
			var matrix:Matrix = new Matrix();
			
			for(var y:uint = 0; y < numTilesY; ++y)
			{
				tileBounds.y = bounds.top + y * (tileHeight - overlap);
				
				/*
				If tileBounds.bottom is greater than bounds.bottom, that means the last tile in this column exceeds the height it needs to be to draw the rest of the DisplayObject.
				If true, shorten the tile's height. If false, keep the tile's height at tileHeight.
				*/
				tileBounds.bottom > bounds.bottom ? tileBounds.bottom = bounds.bottom : tileBounds.height = tileHeight;
				
				for(var x:uint = 0; x < numTilesX; ++x)
				{
					tileBounds.x = bounds.left + x * (tileWidth - overlap);
					
					/*
					If tileBounds.right is greater than bounds.right, that means the last tile in this row exceeds the width it needs to be to draw the rest of the DisplayObject.
					If true, shorten the tile's width. If false, keep the tile's width at tileWidth.
					*/
					tileBounds.right > bounds.right ? tileBounds.right = bounds.right : tileBounds.width = tileWidth;
					
					//BitmapUtils.getBitmapData() modifies the Matrix. Need to reset it before we use it again.
					matrix.setTo(1, 0, 0, 1, 0, 0);
					
					var data:SharedBitmapData = BitmapUtils.getBitmapData(display, tileBounds, matrix, 0, 0, quality, transparent, fillColor);
					
					var color:Rectangle = data.getColorBoundsRect(0xFF000000, 0x00000000, false);
					if(!color.isEmpty())
					{
						var bitmap:Bitmap = BitmapUtils.getBitmap(data, tileBounds.x, tileBounds.y, quality);
						sprite.addChild(bitmap);
					}
					else
					{
						data.dispose();
					}
				}
			}
			
			return sprite;
		}
		
		private static function getBitmapData(display:DisplayObject, bounds:Rectangle, matrix:Matrix, offsetX:Number, offsetY:Number, quality:Number = 1, transparent:Boolean = true, fillColor:uint = 0):SharedBitmapData
		{
			matrix.tx = offsetX - bounds.left;
			matrix.ty = offsetY - bounds.top;
			matrix.scale(quality, quality);
			
			var width:uint 	= Math.ceil(bounds.width * quality);
			var height:uint = Math.ceil(bounds.height * quality);
			
			var data:SharedBitmapData = new SharedBitmapData(width, height, transparent, fillColor);
			
			if(width == 0 || height == 0)
			{
				trace("BitmapUtils.getBitmapData() :: Can't create BitmapData with dimensions of: " + width + "x" + height);
			}
			else
			{
				data.draw(display, matrix);
			}
			
			return data;
		}
		
		private static function getBitmap(data:BitmapData, x:Number, y:Number, quality:Number = 1):SharedBitmap
		{
			var bitmap:SharedBitmap = new SharedBitmap(data);
			bitmap.x 				= x;
			bitmap.y 				= y;
			bitmap.scaleX 			= 1 / quality;
			bitmap.scaleY 			= 1 / quality;
			
			return bitmap;
		}
		
		/**
		 * Checks all of the colors in <code>data</code> and returns an Array of uint colors sorted by frequency. If
		 * <code>transparent</code> is true, an Array of alpha-included colors is returned. If <code>transparent</code>
		 * is false, an Array of alpha-excluded colors is returned.
		 */
		public static function getColorFrequencies(data:BitmapData, transparent:Boolean = true):Array
		{
			var color:uint;
			var colorCounts:Dictionary = new Dictionary();
			
			for(var y:int = data.height - 1; y >= 0; --y)
			{
				for(var x:int = data.width - 1; x >= 0; --x)
				{
					color = transparent ? data.getPixel32(x, y) : data.getPixel(x, y);
					if(!colorCounts[color]) colorCounts[color] = 0;
					++colorCounts[color];
				}
			}
			
			var colors:Array = [];
			var numColors:int;
			do
			{
				var maxColor:uint 	= 0;
				var maxCount:uint 	= 0;
				numColors 			= 0;
				
				for(color in colorCounts)
				{
					++numColors;
					
					if(colorCounts[color] > maxCount)
					{
						maxColor = color;
						maxCount = colorCounts[color];
					}
				}
				
				if(maxCount > 0)
				{
					colors[colors.length] = maxColor;
					delete colorCounts[maxColor];
				}
				
			}
			while(numColors != 0);
			
			return colors;
		}
		
		public static function equalBitmapData(data1:BitmapData, data2:BitmapData, transparent:Boolean = true):Boolean
		{
			if(!data1 || !data2)
			{
				if(!data1 && !data2) return true;
				return false;
			}
			
			if(data1.width != data2.width || data1.height != data2.height) return false;
			
			var x:int;
			var y:int;
			
			if(transparent)
			{
				for(x = data1.width - 1; x >= 0; --x)
				{
					for(y = data1.height - 1; y >= 0; --y)
					{
						if(data1.getPixel32(x, y) != data2.getPixel32(x, y)) return false;	
					}
				}
			}
			else
			{
				for(x = data1.width - 1; x >= 0; --x)
				{
					for(y = data1.height - 1; y >= 0; --y)
					{
						if(data1.getPixel(x, y) != data2.getPixel(x, y)) return false;	
					}
				}
			}
			
			return true;
		}
		
		/**
		 * Recursively iterates through a DisplayObjectContainer's children, finding its bottom-most
		 * DisplayObjects and bitmapping them.
		 * 
		 * <listing version="3.0">
		 * <p><b>TO-DO :: Finish this How-To!</b></p>
		 * <ul>
		 * 		<li>Every DisplayObject in a MovieClip with more than 1 frame must exist on every frame.</li>
		 * 		<ul>
		 * 			<li>This is because the same DisplayObject on different frames separated by empty frames are considered different instances.</li>
		 * 			<li>DisplayObjects should have an alpha = 0 if they're not to be seen on certain frames.</li>
		 * 		</ul>
		 * 		<li>DisplayObjects (such as Shapes) <b>can't</b> be replaced in a MovieClip with multiple frames. This will result in 2 behaviors.</li>
		 * 		<ul>
		 * 			<li>Old DisplayObjects may not be removed.</li>
		 * 			<li>New DisplayObjects will appear on <b>all</b> frames.</li>
		 * 		</ul>
		 * </ul>
		 * </listing>
		 */
		public static function convertContainer(container:DisplayObjectContainer, quality:Number = 1, data:Vector.<BitmapData> = null):void
		{
			var canBitmap:Boolean 	= true;
			var isClip:Boolean 		= false;
			
			if(container is MovieClip)
			{
				isClip		= true;
				canBitmap 	= MovieClip(container).totalFrames == 1;
				MovieClip(container).gotoAndStop(1);
			}
			
			for(var index:int = container.numChildren - 1; index >= 0; --index)
			{
				var child:DisplayObject = container.getChildAt(index);
				
				if(child is DisplayObjectContainer)
				{
					BitmapUtils.convertContainer(child as DisplayObjectContainer, quality, data);
				}
				else if(canBitmap && (!(child is Bitmap)))
				{
					var bitmap:SharedBitmap = BitmapUtils.createBitmap(child, quality);
					DisplayUtils.swap(bitmap, child);
					
					if(data)
					{
						data.push(bitmap.bitmapData);
					}
				}
			}
			
			//Reset the MovieClip back to playing.
			if(isClip)
			{
				MovieClip(container).gotoAndPlay(1);
			}
		}
	}
}