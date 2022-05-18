package org.flintparticles.common.displayObjects 
{
	/**
	 * Author: Drew Martin
	 */
	import flash.display.Shape;
	
	public class Droplet extends Shape
	{
		private var _radius:Number;
		private var _color:uint;
		
		public function Droplet(radius:Number = 1, color:uint = 0xFFFFFF, bm:String = "normal")
		{
			_radius = radius;
			_color = color;
			draw();
			blendMode = bm;
			//cacheAsBitmap = true;
		}
		
		private function draw():void
		{
			graphics.clear();
			graphics.beginFill(_color);
			graphics.moveTo(0, _radius);
			
			/**
			 * All (_radius * 3)'s could be replaced with a different variable. This value
			 * determines how long the droplet "tail" should be.
			 */
			
			//Front "C" Curve
			graphics.curveTo(_radius, 					_radius, 		_radius, 				0);
			graphics.curveTo(_radius, 					-_radius, 		0, 						-_radius);
			
			//Top "S" Curve
			graphics.curveTo(-(_radius * 3) * 0.5, 		-_radius, 		-(_radius * 3), 		-_radius * 0.5);
			graphics.curveTo(-(_radius * 3) * 1.5, 		0, 				-(_radius * 3) * 2, 	0);
			
			//Bottom "S" Curve
			graphics.curveTo(-(_radius * 3) * 1.5, 		0, 				-(_radius * 3), 		_radius * 0.5);
			graphics.curveTo(-(_radius * 3) * 0.5, 		_radius, 		0, 						_radius);
			
			graphics.lineTo(0, _radius);
			graphics.endFill();
		}
		
		public function get radius():Number
		{
			return _radius;
		}
		public function set radius(radius:Number):void
		{
			_radius = radius;
			draw();
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