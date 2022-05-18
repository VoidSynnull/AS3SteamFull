package game.components.hit
{
	import flash.geom.Point;
	
	import ash.core.Component;
	
	public class Mover extends Component
	{
		public var velocity:Point;
		public var acceleration:Point;
		public var rotationVelocity:Number;
		public var friction:Point;
		public var stickToPlatforms:Boolean;
		public var overrideVelocity:Boolean;
	}
}
