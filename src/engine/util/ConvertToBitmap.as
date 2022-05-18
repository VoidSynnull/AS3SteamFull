package engine.util
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObjectContainer;
	/**
	 * ...
	 * @author billy
	 */
	public class ConvertToBitmap 
	{
		public function convert(target:DisplayObjectContainer, container:DisplayObjectContainer):void
		{
			bitmapData = new BitmapData(target.width, target.height, true, 0x000000);
 
			// draw the source data into the BitmapData object
			bitmapData.draw(target);
			 
			// make a new Bitmap object and populate with the BitmapData object
			bitmap = new Bitmap(bitmapData);
			 
			// add Bitmap to stage
			container.addChild(bitmap);
		}
		
		public var bitmap:Bitmap;
		public var bitmapData:BitmapData;
	}
	
}