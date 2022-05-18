package org.flintparticles.common.displayObjects
{
	import flash.display.Shape;
	
	public class Boomerang extends Shape
	{
		public function Boomerang(size:Number, color:uint = 0xFFFFFF)
		{
			_size = size;
			_color = color;
			draw();
		}
		
		public function draw():void
		{
			graphics.clear();
			graphics.beginFill(color);
			graphics.cubicCurveTo(_size*.15, -_size*.9, _size*.85, -_size*.9, _size, 0);
			graphics.cubicCurveTo(_size*.85, -_size*.4, _size*.15, -_size*.4, 0, 0);
			graphics.endFill();
		}
		
		public function get size():Number
		{
			return _size;
		}
		
		public function set size(value:Number):void
		{
			_size = value;
			draw();
		}
		
		public function get color():uint
		{
			return _color;
		}
		
		public function set color(value:uint):void
		{
			_color = value;
			draw();
		}
		
		private var _size:Number;
		private var _color:uint;
	}
}