package game.data.ui
{
	import flash.geom.Rectangle;

	public class RectSlot
	{
		public var index:int;
		public var rect:Rectangle;
		
		public function RectSlot( index:int = -1, rect:Rectangle = null )
		{
			super();
			this.index = index;
			if( rect != null )
			{
				this.rect = rect;
			}
		}
		
		public function clone():RectSlot
		{
			var newRect:RectSlot = new RectSlot();
			newRect.rect = this.rect.clone();
			newRect.index = index;
			return newRect;
		}
	}
}