package game.scenes.testIsland.drewTest.classes
{
	import flash.geom.Point;
	
	import game.util.Utils;

	public class WaterPoint
	{
		private var _point:Point;
		private var _time:Number;
		public var magnitude:Number;
		
		public function WaterPoint(x:Number, y:Number)
		{
			this._point = new Point(x, y);
			this._time = Utils.randNumInRange(0, Math.PI * 2);
			this.magnitude = Utils.randNumInRange(20, 30);
		}
		
		public function get point():Point { return this._point; }
		
		public function get time():Number { return this._time; }
		public function set time(number:Number):void { this._time = number; }
	}
}