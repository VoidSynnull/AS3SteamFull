package engine.data.display
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	
	public class SharedBitmap extends Bitmap
	{
		public function SharedBitmap(data:BitmapData = null, pixelSnapping:String = "auto", smoothing:Boolean = false)
		{
			if(data && data is SharedBitmapData)
			{
				++SharedBitmapData(data)._bitmapsAddedTo;
			}
			
			super(data, pixelSnapping, smoothing);
		}
		
		public function destroy():void
		{
			this.bitmapData.dispose();
			this.bitmapData = null;
		}
		
		override public function set bitmapData(data:BitmapData):void
		{
			var previousData:BitmapData = this.bitmapData;
			
			if(previousData == data) return;
			
			if(previousData && previousData is SharedBitmapData)
			{
				--SharedBitmapData(previousData)._bitmapsAddedTo;
			}
			
			if(data && data is SharedBitmapData)
			{
				++SharedBitmapData(data)._bitmapsAddedTo;
			}
			
			super.bitmapData = data;
		}
	}
}