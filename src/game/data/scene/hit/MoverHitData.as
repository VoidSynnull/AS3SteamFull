package game.data.scene.hit 
{
	import flash.geom.Point;
	
	import ash.core.Entity;

	public class MoverHitData extends HitDataComponent
	{
		public var velocity:Point;
		public var acceleration:Point;
		public var rotationVelocity:Number;
		public var friction:Point;
		public var stickToPlatforms:Boolean = false;
		public var bounce:Number = 0;
        public var overrideVelocity:Boolean = false;
		public var animate:Boolean = false;
		public var timeline:Entity;
	}
}