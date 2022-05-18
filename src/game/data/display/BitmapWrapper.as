package game.data.display
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	
	import game.util.DisplayUtils;
	
	public class BitmapWrapper
	{
		public var source : DisplayObject;
		public var data : BitmapData;
		public var tileData : Array;
		public var bitmap:Bitmap;
		public var sprite:Sprite;
		public var depth:Number = 1;
		
		public function destroy( disposeData:Boolean = true ):void
		{
			if( disposeData )
			{
				if(data)
				{
					data.dispose();
					data = null;
				}
				
				if(bitmap)
				{
					bitmap.bitmapData.dispose();
				}
			}
			
			sprite = null;
			source = null;
			bitmap = null;
			
			if(tileData)
			{
				for(var n:int = 0; n < tileData.length; n++)
				{
					BitmapData(tileData[n]).dispose();	
				}
			}
		}
		
		public function sourceVisible( show:Boolean = true ):void
		{
			if( source != null && bitmap != null )
			{
				if( show )
				{
					DisplayUtils.swap( bitmap, source );
				}
				else
				{
					DisplayUtils.swap( source, bitmap );
				}
			}
		}
		
		/**
		 * Duplicates the BitmapWrapper
		 * @return 
		 * 
		 */
		public function duplicate( shareData:Boolean = true, includeSource:Boolean = false ):BitmapWrapper
		{
			var copyWrapper:BitmapWrapper = new BitmapWrapper();
			
			if( shareData )
			{
				copyWrapper.bitmap = new Bitmap( this.data );
			}
			else
			{
				copyWrapper.data = this.data.clone();
				copyWrapper.bitmap = new Bitmap( copyWrapper.data  );
			}
			copyWrapper.bitmap.x = this.bitmap.x;
			copyWrapper.bitmap.y = this.bitmap.y;
			copyWrapper.bitmap.width = this.bitmap.width;
			copyWrapper.bitmap.height = this.bitmap.height;
			
			if( this.sprite )
			{
				copyWrapper.sprite = new Sprite();
				copyWrapper.sprite.addChild(copyWrapper.bitmap);
				copyWrapper.sprite.transform = this.sprite.transform;
				copyWrapper.sprite.name = this.sprite.name;
				copyWrapper.sprite.mouseEnabled = this.sprite.mouseEnabled;
				copyWrapper.sprite.mouseChildren = this.sprite.mouseChildren;
			}
			
			if( includeSource )
			{
				copyWrapper.source = this.source;
			}
			return copyWrapper;
		}

		/**
		 * Removes Bitmap & bitmapData, leaving source and sprite intact so that a new bitmap can be created.
		 */
//		public function removeBitmap():void
//		{
//			if(data)
//			{
//				data.dispose();
//				data = null;
//			}
//			sprite.removeChild( bitmap );
//			bitmap = null;
//			
//			if(tileData)
//			{
//				for(var n:int = 0; n < tileData.length; n++)
//				{
//					BitmapData(tileData[n]).dispose();	
//				}
//			}
//		}
		
		/**
		 * Replace current bitmap content with that of the passed BitmapWrapper.
		 * Does not replace sprite, so that current transforms and parentage remain the same.
		 * @param bitmapWrapper
		 * 
		 */
//		public function swap( bitmapWrapper:BitmapWrapper ):void
//		{
//			if(data)
//			{
//				data.dispose();
//			}
//			if(tileData)
//			{
//				for(var n:int = 0; n < tileData.length; n++)
//				{
//					BitmapData(tileData[n]).dispose();	
//				}
//			}
//			data = bitmapWrapper.data;
//			DisplayUtils.swap( bitmapWrapper.bitmap, bitmap );
//			bitmap = bitmapWrapper.bitmap;
//		}
		
		/**
		 * Removes Bitmap & bitmapData, leaving source and sprite intact so that a new bitmap can be created.
		 * Provides basic bitmap creation.
		 */
//		public function redraw( scale:Number = 1, buffer:int = 0, clipRectangle:Rectangle = null, transparent:Boolean=true, fill:Number=0x00000000 ):void
//		{
//			removeBitmap();
//			var displayObjectBounds:Rectangle = sprite.getBounds( sprite );
//			
//			// if this displayObject is empty, there is nothing to do.
//			if(displayObjectBounds.width == 0 || displayObjectBounds.height == 0)
//			{
//				return;
//			}
//			
//			var offsetMatrix:Matrix = new Matrix();
//			// offset the bitmap if the display object is not at 0,0 (top-left registered).
//			offsetMatrix.translate(-displayObjectBounds.left - buffer, -displayObjectBounds.top - buffer);
//			// apply a custom scale if needed.
//			if( scale != 1 )
//			{
//				offsetMatrix.scale(scale, scale);
//			}
//			
//			data = new BitmapData( displayObjectBounds.width, displayObjectBounds.height, transparent, fill);
//			data.draw( sprite, offsetMatrix, null, null, clipRectangle );
//			
//			// position the bitmap to match the original display object's position.
//			bitmap = new Bitmap(data);
//			bitmap.x -= offsetMatrix.tx / scale;
//			bitmap.y -= offsetMatrix.ty / scale;
//			
//			sprite.addChild(bitmap);
//			
//			// adjust the dimensions of the bitmap to match the original display object.
//			bitmap.width /= scale;
//			bitmap.height /= scale;
//		}
	}
}