/*
 * FLINT PARTICLE SYSTEM
 * .....................
 * 
 * Author: Richard Lord
 * Copyright (c) Richard Lord 2008-2011
 * http://flintparticles.org
 * 
 * 
 * Licence Agreement
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

package org.flintparticles.common.displayObjects 
{
	import flash.display.Shape;		

	/**
	 * The Rect class is a DisplayObject that is a rectangle shape. The 
	 * registration point of this display object is in the center of the
	 * rectangle.
	 */

	public class Confetti extends Shape 
	{
		private var _size:Number;
		private var _color:uint;

		/**
		 * The constructor creates a Rect with the specified width and height.
		 * 
		 * @param width The width, in pixels, of the rectangle.
		 * @param height The height, in pixels, of the rectangle.
		 * @param color the color of the rectangle
		 * @param bm The blendMode for the rectangle
		 */
		public function Confetti( size:Number, color:uint = 0xFFFFFF )
		{
			_size = size;
			_color = color;
			draw();
		}
		
		private function draw():void
		{	
			graphics.clear();
			graphics.beginFill( this._color );

			graphics.moveTo( -_size * .34, -_size * .18 );
			graphics.lineTo( -_size * .16, -_size * .56 );
			graphics.lineTo( _size * .37, _size * .4);
			graphics.lineTo( _size * .13, _size * .44);
			
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
	}
}
