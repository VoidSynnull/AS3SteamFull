package game.components.timeline
{
	import flash.display.Bitmap;
	
	import ash.core.Component;

	public class BitmapTimeline extends Component
	{
		/**
		 * bitmapContainer inside the main movieclip that displays the current bitmap.
		 * This should not be the base clip, because it gets offset when the currently displayed
		 * bitmap changes.
		 */
		public var bitmap:Bitmap;
		public var frame:int;

		public function BitmapTimeline(bitmap:Bitmap)
		{
			this.bitmap = bitmap;

		}
	}
}