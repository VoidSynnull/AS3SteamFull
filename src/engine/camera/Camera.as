package engine.camera
{
	import flash.geom.Point;
	import flash.geom.Rectangle;

	public class Camera
	{
		public function Camera(viewportWidth:Number, viewportHeight:Number, areaWidth:Number, areaHeight:Number, areaX:Number = 0, areaY:Number = 0)
		{
			_initArea = new Rectangle(areaX, areaY, areaWidth, areaHeight);
			
			_view = new Rectangle(0, 0, 0, 0);
			_area = new Rectangle(0, 0, 0, 0);
			
			_min = new Point(0, 0);
			_max = new Point(0, 0);
			_center = new Point(0, 0);
			_delta = new Point(0, 0);
			
			resize(viewportWidth, viewportHeight, areaWidth, areaHeight, areaX, areaY);
		}
			
		public function destroy():void
		{
			_view = null;
			_area = null;
			_min = null;
			_max = null;
		}
		
		public function resize(viewportWidth:Number, viewportHeight:Number, areaWidth:Number, areaHeight:Number, areaX:Number = 0, areaY:Number = 0):void
		{
			_view.width = viewportWidth;
			_view.height = viewportHeight;
			
			_area.x = areaX;
			_area.y = areaY;
			_area.width = areaWidth;
			_area.height = areaHeight;
			
			_center.x = viewportWidth * .5;
			_center.y = viewportHeight * .5;
			
			_min.x = areaX + _center.x;
			_min.y = areaY + _center.y;
			
			_max.x = areaX + areaWidth - _center.x;
			_max.y = areaY + areaHeight - _center.y;
		}
				
		public function update(x:Number, y:Number):void
		{											
			_delta.x = 0;
			_delta.y = 0;

			if (x >= _max.x)
			{
				_view.x = _max.x - _center.x;
			}
			else if (x < _min.x)
			{
				_view.x = _min.x - _center.x;
			}
			else
			{
				_delta.x = x - this.targetX;
				
				_view.x += _delta.x;
			}

			if (y >= _max.y)
			{
				_view.y = _max.y - _center.y;
			}
			else if (y < _min.y)
			{
				_view.y = _min.y - _center.y;
			}
			else
			{
				_delta.y = y - this.targetY;
				
				_view.y += _delta.y;
			}
		}
		
		public function set scale(scale:Number):void
		{
			_min.x = _area.x + this.viewportWidth * (.5 / scale);
			_min.y = _area.y + this.viewportHeight * (.5 / scale);
						
			_max.x = _area.x + this.areaWidth - this.viewportWidth * (.5 / scale);
			_max.y = _area.y + this.areaHeight - this.viewportHeight * (.5 / scale);
			
			_scale = scale;
		}
		
		public function get max():Point { return(_max); }
		public function get min():Point { return(_min); }
		public function set max(max:Point):void { _max = max; }
		public function set min(min:Point):void { _min = min; }
		public function set area(area:Rectangle):void { _area = area; this.scale = _scale; } 
		public function get area():Rectangle { return(_area); }
		public function get x():Number { return(_view.x); }
		public function get y():Number { return(_view.y); }
		public function get targetDeltaX():Number { return(_delta.x); }
		public function get targetDeltaY():Number { return(_delta.y); }
		public function get viewportWidth():Number { return(_view.width); }
		public function get viewportHeight():Number { return(_view.height); }
		public function get areaWidth():Number { return(_area.width); }
		public function get areaHeight():Number { return(_area.height); }
		public function get targetX():Number { return(_view.x + _center.x); }
		public function get targetY():Number { return(_view.y + _center.y); }
		public function get center():Point { return(_center); }
		public function get initAreaWidth():Number { return(_initArea.width); }
		public function get initAreaHeight():Number { return(_initArea.height); }
		public function get viewport():Rectangle { return(_view); }
		public function get scale():Number { return(_scale); }
		
		private var _initArea:Rectangle;
		private var _area:Rectangle;
		private var _view:Rectangle;
		private var _min:Point;
		private var _max:Point;
		private var _center:Point;
		private var _delta:Point;
		private var _scale:Number = 1;
	}
}