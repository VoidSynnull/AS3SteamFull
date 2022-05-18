package org.flintparticles.common.displayObjects
{
    import flash.display.GradientType;
    import flash.display.Shape;
    import flash.geom.Matrix;

    public class RadialEllipse extends Shape
    {
        private var _ellipseWidth:Number;
        private var _ellipseHeight:Number;
        private var _color:uint;
		
		public function RadialEllipse(width:Number = 1, height:Number = 1, color:uint = 0xFFFFFF, bm:String = "normal")
        {
            _ellipseWidth = width;
            _ellipseHeight = height;
            _color = color;
            draw();
            blendMode = bm;
			//this.cacheAsBitmap = true;
        }

        private function draw():void
        {
			graphics.clear();
			var matrix:Matrix = new Matrix();
			matrix.createGradientBox(_ellipseWidth, _ellipseHeight, 0, -_ellipseWidth * 0.5, -_ellipseHeight * 0.5);
			graphics.beginGradientFill(GradientType.RADIAL, [_color, _color], [0.5, 0], [0, 255], matrix);
			graphics.drawEllipse(-_ellipseWidth * 0.5, -_ellipseHeight * 0.5, _ellipseWidth, _ellipseHeight);
			graphics.endFill();
        }

        public function get ellipseWidth():Number
        {
            return _ellipseWidth;
        }
        public function set ellipseWidth(width:Number):void
        {
			if(width <= 0) _ellipseWidth = 1;
			else _ellipseWidth = width;
            draw();
        }

        public function get ellipseHeight():Number
        {
            return _ellipseHeight;
        }
        public function set ellipseHeight(height:Number):void
        {
			if(height <= 0) _ellipseHeight = 1;
			else _ellipseHeight = height;
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