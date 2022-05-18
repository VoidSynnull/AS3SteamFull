package game.scenes.shrink.livingRoomShrunk.Particles
{
	import flash.display.Shape;
	import flash.geom.Point;
	
	public class StaticSpark extends Shape
	{
		private var _length:Number;
		private var _zigs:uint;
		private var _color:uint;
		private var _thickness:Number;
		
		/**
		 * The constructor  creates a static electricity visual.
		 * @param length 	the approx length of the static bolt
		 * @param zigs 		the approx number of zigs in the bolt
		 * @param thickness the thickness of the bolt
		 * @param color		Color of the bolt
		 * @param bm    	Blend mode of the ring
		 */
		
		public function StaticSpark(length:Number = 100, zigs:uint = 10, thickness:Number = 1, color:uint = 0xFFFFFF, bm:String = "normal")
		{
			_length = length;
			_zigs = zigs;
			_thickness = thickness;
			_color = color;
			draw();
			blendMode = bm;
		}
		
		private function draw():void
		{
			var lastPoint:Point = new Point();
			var zigLength:Number = _length / _zigs;
			var lengthLeft:Number = _length;
			graphics.lineStyle(_thickness,_color);
			while(lengthLeft > 0)
			{
				var randomDirection:Number = Math.random() * 2 * Math.PI;
				var drawLength:Number = zigLength;
				drawLength *= Math.random() * 2;// potentially average out to 1
				
				var drawPoint:Point = new Point(lastPoint.x + Math.cos(randomDirection) * drawLength, lastPoint.y + Math.sin(randomDirection) * drawLength);
				graphics.lineTo(drawPoint.x, drawPoint.y);
				lastPoint = drawPoint;
				lengthLeft -= drawLength;
			}
		}
		
		
		public function get color():uint
		{
			return _color;
		}
		public function set color( value:uint ):void
		{
			_color = value;
			draw();
		}
	}
}