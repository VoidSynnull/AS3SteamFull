package game.scenes.backlot.postProduction.ScrollingSystem
{
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Component;
	
	public class Scroll extends Component
	{
		public var speed:Point;
		public var bounds:Rectangle;
		
		public var scroll:Boolean;
		
		public function Scroll(speed:Point = null, bounds:Rectangle = null, scroll:Boolean = true)
		{
			this.speed = speed;
			if(this.speed == null)
				this.speed = new Point();
			
			this.bounds = bounds;
			if(this.bounds == null)
				this.bounds = new Rectangle();
			
			this.scroll = scroll;
		}
	}
}