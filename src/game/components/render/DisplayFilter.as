package game.components.render
{
	import flash.display.Bitmap;
	import flash.filters.BitmapFilter;
	import flash.geom.Point;
	
	import ash.core.Component;
	
	public class DisplayFilter extends Component
	{
		/**
		 * Bitmap used by the system. Should not be touched.
		 */
		public var bitmap:Bitmap;
		public var filters:Vector.<BitmapFilter> = new Vector.<BitmapFilter>();
		public var inflate:Point = new Point();
		
		public function DisplayFilter()
		{
			super();
		}
	}
}