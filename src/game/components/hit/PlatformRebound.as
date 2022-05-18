package game.components.hit
{
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Component;
	
	public class PlatformRebound extends Component
	{
		public var friction:Point;
		public var height:Number;	// Used to store actual height of platform w/o rotation for angled hits.
		public var bounce:Number = 0;
		public var top:Boolean;  // set to true to move entities to top of platform rather then center.
		public var stickToPlatforms:Boolean = false;         // This will cause entities to 'stick' to platforms even if another force is acting on them.
		
		public var hitRect:Rectangle;	// rectangle used to test collisions, position relative to spatial

	}
}