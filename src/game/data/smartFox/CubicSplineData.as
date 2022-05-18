package game.data.smartFox
{
	import flash.geom.Point;

	public class CubicSplineData
	{
		public var posOld:Point = new Point();
		public var posNew:Point = new Point();
		
		public var velOld:Point = new Point();
		public var velNew:Point = new Point();
		
		public var coord0:Point = new Point();
		public var coord1:Point = new Point();
		public var coord2:Point = new Point();
		public var coord3:Point = new Point();
		
		public var a:Number = 0;
		public var b:Number = 0;
		public var c:Number = 0;
		public var d:Number = 0;
		public var e:Number = 0;
		public var f:Number = 0;
		public var g:Number = 0;
		public var h:Number = 0;
		public var time:Number = 0;
		
		public function CubicSplineData()
		{
		}
		
		public function recalculate():void
		{
			coord0.setTo(posOld.x, posOld.y);
			coord1.setTo(posOld.x + velOld.x, posOld.y + velOld.y);
			coord2.setTo(posNew.x - velNew.x, posNew.y - velNew.y);
			coord3.setTo(posNew.x, posNew.y);
			
			a = coord3.x - (3 * coord2.x) + (3 * coord1.x) - coord0.x;
			b = (3 * coord2.x) - (6 * coord1.x) + (3 * coord0.x);
			c = (3 * coord1.x) - (3 * coord0.x);
			d = coord0.x;
			
			e = coord3.y - (3 * coord2.y) + (3 * coord1.y) - coord0.y;
			f = (3 * coord2.y) - (6 * coord1.y) + (3 * coord0.y);
			g = (3 * coord1.y) - (3 * coord0.y);
			h = coord0.y;
			
			time = 0;
		}
		
		public function get x():Number
		{
			return (a * Math.pow(time, 3)) + (b * Math.pow(time, 2)) + (c * time) + d;
		}
		
		public function get y():Number
		{
			return (e * Math.pow(time, 3)) + (f * Math.pow(time, 2)) + (g * time) + h;
		}
	}
}