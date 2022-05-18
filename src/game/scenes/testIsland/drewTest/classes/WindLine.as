package game.scenes.testIsland.drewTest.classes
{
	import flash.geom.Point;
	
	import org.as3commons.collections.ArrayList;

	public class WindLine
	{
		public static const INIT_STATE:String	= "INIT_STATE";
		public static const MOVE_STATE:String	= "MOVE_STATE";
		public static const SPIN_STATE:String	= "SPIN_STATE";
		
		private var _state:String;
		
		private var _numPoints:int;
		private var _points:ArrayList;
		
		private var _spinCenter:Point;
		private var _isClockwise:Boolean;
		public var offsetY:Number = 2.5;
		
		private var _speed:Number;
		private var _time:Number;
		
		public function WindLine(numPoints:int, speed:Number)
		{
			this._state = WindLine.INIT_STATE;
			
			this._numPoints = numPoints;
			this._points = new ArrayList();
			
			this._spinCenter = new Point();
			if(Math.random() > 0.5) this._isClockwise = true;
			else this._isClockwise = false;
			
			this._speed = speed;
			this._time = 0;
		}
		
		public function get state():String { return this._state; }
		public function set state(state:String):void { this._state = state; }
		
		public function get numPoints():Number { return this._numPoints; }
		public function set numPoints(numPoints:Number):void { this._numPoints = numPoints; }
		
		public function get points():ArrayList { return this._points; }
		
		public function get speed():Number { return this._speed; }
		public function set speed(speed:Number):void { this._speed = speed; }
		
		public function get time():Number { return this._time; }
		public function set time(time:Number):void { this._time = time; }
	}
}