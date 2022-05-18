package game.scenes.testIsland.drewTest.classes
{
	import flash.geom.Point;

	public class SurfacePoint
	{
		public var center:Point;
		public var point:Point;
		public var isMoving:Boolean;
		public var speed:Number;
		public var magnitude:Point;
		public var time:Number;
		
		public function SurfacePoint(x:Number, y:Number)
		{
			this.center = new Point(x, y);
			this.point = new Point(x, y);
			this.isMoving = false;
			this.speed = 5;
			this.magnitude = new Point();
			this.time = 0;
		}
	}
}