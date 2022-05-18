package game.scenes.virusHunter.mouth.displayObjects
{
	import flash.display.Sprite;
	
	public class Bolt extends Sprite
	{
		private var _thickness:Number;
		private var _width:Number;
		private var _color:uint;
		
		/**
		 * The constructor creates a Dot with a specified radius.
		 * @param radius The radius, in pixels, of the Dot.
		 * @param color The color of the Dot.
		 * @param bm The blendMode for the Dot.
		 */
		public function Bolt( thickness:Number = .5, color:uint = 0xFFFFFF, bm:String = "normal" )
		{
			_thickness = thickness;
			_width = thickness*0.8;
			_color = color;
			draw();
			blendMode = bm;
		}
		
		private function draw():void
		{
		/*	if( _ellipseWidth > 0 && _ellipseHeight > 0 )
			{
				graphics.clear();
				graphics.beginFill( _color );
				graphics.
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
			}*/
			
			graphics.clear();
			graphics.lineStyle( _thickness, _color, Math.random()*100 );
			
			var pointX:Number = -1;
			var pointY:Number =  Math.random() * 1;
			
			graphics.moveTo( pointX, pointY );
			
			for (var i:int = 0; i <= 4; i++) 
			{
				pointX = i;
				pointY = Math.random() * 3;
				graphics.lineTo( pointX, pointY );
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