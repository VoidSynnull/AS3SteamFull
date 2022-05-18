package game.scenes.testIsland.drewTest.components
{
	import flash.geom.Rectangle;
	
	import ash.core.Component;
	
	import org.as3commons.collections.ArrayList;
	
	public class FloodWater extends Component
	{
		private var _resetPoints:Boolean;
		
		private var _box:Rectangle;
		private var _height:Number;
		
		private var _numPoints:int;
		private var _points:ArrayList;
		
		private var _speed:Number;
		private var _magnitude:Number;
		private var _time:Number;
		
		public function FloodWater(box:Rectangle, height:Number, numPoints:int)
		{
			this._resetPoints = true;
			
			this._box = box;
			this._height = height;
			
			this._numPoints = numPoints;
			this._points = new ArrayList();
			
			this._speed = 5;
			this._magnitude = 1;
			this._time = 0;
		}
		
		public function get resetPoints():Boolean { return this._resetPoints; }
		public function set resetPoints(boolean:Boolean):void { this._resetPoints = boolean; }
		
		public function get box():Rectangle { return this._box; }
		public function set box(box:Rectangle):void { this._box = box; }
		
		public function get numPoints():int { return this._numPoints; }
		public function set numPoints(number:int):void
		{ this._numPoints = number; if(this._numPoints < 1) this._numPoints = 1; }
		
		public function get height():Number { return this._height; }
		public function set height(number:Number):void { this._height = number; }
		
		public function get points():ArrayList { return this._points; }
		
		public function get speed():Number { return this._speed; }
		public function set speed(number:Number):void { this._speed = number;; }
		
		public function get magnitude():Number { return this._magnitude; }
		public function set magnitude(number:Number):void { this._magnitude = number; }
		
		public function get time():Number { return this._time; }
		public function set time(number:Number):void { this._time = number; }
	}
}