package game.scenes.shrink.kitchenShrunk01.components
{
	import flash.display.MovieClip;
	import flash.geom.Rectangle;
	
	import ash.core.Component;
	import ash.core.Entity;
	
	public class Plug extends Component
	{
		public var cord:MovieClip;
		
		public var holdingPlug:Boolean;
		public var socket:Entity;
		public var follow:Entity;
		public var goodZone:Rectangle;
		public var shockEntity:Entity;
	}
}