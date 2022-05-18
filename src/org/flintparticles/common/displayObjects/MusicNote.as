/*
 created by Jordan Leary to extend flint display objects
 */

package org.flintparticles.common.displayObjects
{
    import flash.display.Shape;

    /**
     * The Ellipse class is a DisplayObject with a oval shape. The registration point
     * of this diaplay object is in the center of the Ellipse.
     */

    public class MusicNote extends Shape
    {
        private var _ellipseWidth:Number;
        private var _ellipseHeight:Number;
        private var _color:uint;

        /**
         * The constructor creates a Dot with a specified radius.
         * @param radius The radius, in pixels, of the Dot.
         * @param color The color of the Dot.
         * @param bm The blendMode for the Dot.
         */
        public function MusicNote( width:Number = 1, color:uint = 0xFFFFFF, bm:String = "normal" )
        {
            _ellipseWidth = width;
            _ellipseHeight = width*0.8;
            _color = color;
            draw();
            blendMode = bm;
        }

        private function draw():void
        {
        	if( _ellipseWidth > 0 && _ellipseHeight > 0 )
        	{
	            graphics.clear();
	            graphics.beginFill( _color );
	            graphics.drawEllipse( 0, 0, _ellipseWidth, _ellipseHeight );
	            graphics.endFill();
				
				graphics.lineStyle( 2, _color );
				if (Math.random() < 0.5) {
					graphics.moveTo( _ellipseWidth, _ellipseHeight/2 );
					graphics.lineTo( _ellipseWidth, -_ellipseWidth*2 );
				}
				else {
					graphics.moveTo( 0, _ellipseHeight/2 );
					graphics.lineTo( 0, _ellipseWidth*2 );
				}
        	}
        }

        public function get ellipseWidth():Number
        {
            return _ellipseWidth;
        }
        public function set ellipseWidth( value:Number ):void
        {
            _ellipseWidth = value;
            draw();
        }

        public function get ellipseHeight():Number
        {
            return _ellipseHeight;
        }
        public function set ellipseHeight( value:Number ):void
        {
            _ellipseHeight = value;
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