package game.components.ui
{
	import flash.display.DisplayObjectContainer;
	import flash.geom.Rectangle;
	
	import ash.core.Component;
	
	public class Crop extends Component
	{
		public var image:DisplayObjectContainer;
		public var rect:Rectangle;
		public function Crop(image:DisplayObjectContainer, rec:Rectangle = null)
		{
			this.image = image;
			if(rec == null)
				rec = new Rectangle();
			rect = new Rectangle();
			rect.copyFrom(rec);
		}
	}
}