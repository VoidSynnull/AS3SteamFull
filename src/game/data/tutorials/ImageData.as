package game.data.tutorials
{
	import flash.display.DisplayObject;

	public class ImageData
	{
		/**
		 * 
		 * These images specified will be placed on top of the overlay.
		 * So the x and y are the viewport
		 * 
		 * @param displayObject - the image to place on top of the overlay
		 * @param x - x position
		 * @param y - y position
		 * 
		 */		
		public function ImageData(displayObject:DisplayObject, x:Number, y:Number)
		{
			this.display = displayObject;
			this.xLoc = x;
			this.yLoc = y;
		}
		
		public var display:DisplayObject
		public var xLoc:Number;
		public var yLoc:Number;
	}
}