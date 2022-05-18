/*
 Created by Jordan Leary to extend flint display objects
 */

package org.flintparticles.common.displayObjects
{
    import flash.display.Shape;

    /**
     * The Ellipse class is a DisplayObject with a oval shape. The registration point
     * of this diaplay object is in the center of the Ellipse.
     */

    public class Blob extends Shape
    {
        private var _radius:Number;
		private var _startRadius:Number;
        private var _color:uint;

        /**
         * The constructor creates a randomly-shaped Blob with a specified target radius.
         * @param radius The radius, in pixels, of the Blob.
         * @param color The color of the Blob.
         * @param bm The blendMode for the Blob.
         */
        public function Blob( radius:Number = 1, color:uint = 0xFFFFFF, bm:String = "normal" )
        {
            _radius = radius;
			_startRadius = radius;
            _color = color;
            draw();
            blendMode = bm;
        }
		
		private function draw():void
		{
			var tanValue:Number = Math.tan(Math.PI/8);
			var sinValue:Number = Math.sin(Math.PI/4);
			
			graphics.clear();
			graphics.beginFill(_color);
			graphics.moveTo(_radius, 0);
			offsetRadius();
			graphics.curveTo(_radius, tanValue*_radius, sinValue*_radius, sinValue*_radius);
			offsetRadius();
			graphics.curveTo(tanValue*_radius, _radius, 0, _radius);
			offsetRadius();
			graphics.curveTo(-tanValue*_radius, _radius, -sinValue*_radius, sinValue*_radius);
			offsetRadius();
			graphics.curveTo(-_radius, tanValue*_radius, -_radius, 0);
			offsetRadius();
			graphics.curveTo(-_radius, -tanValue*_radius, -sinValue*_radius, -sinValue*_radius);
			offsetRadius();
			graphics.curveTo(-tanValue*_radius, -_radius, 0, -_radius);
			offsetRadius();
			graphics.curveTo(tanValue*_radius, -_radius, sinValue*_radius, -sinValue*_radius);
			_radius = _startRadius;
			graphics.curveTo(_radius, -tanValue*_radius, _radius, 0);
			graphics.endFill();
		}
		
		private function offsetRadius():void
		{
			_radius = _startRadius + Math.random()*(_startRadius/2) - _startRadius/4;
		}

        public function get radius():Number
        {
            return _radius;
        }
        public function set radius( value:Number ):void
        {
            _radius = value;
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