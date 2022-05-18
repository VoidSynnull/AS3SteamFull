package game.scenes.testIsland.drewTest.classes
{
	import flash.display.DisplayObjectContainer;
	import flash.display.Shape;
	
	import org.as3commons.collections.ArrayList;

	public class LightningBolt
	{
		public static const INIT_STATE:String		= "INIT_STATE";
		public static const STRIKE_STATE:String		= "STRIKE_STATE";
		public static const FLASH_STATE:String		= "FLASH_STATE";
		
		private var _state:String;
		private var _shape:Shape;
		private var _points:ArrayList;
		private var _numPoints:int;
		
		private var _canFlash:Boolean;
		private var _numFlashes:int;
		
		private var _time:Number;
		
		public function LightningBolt(shape:Shape, numPoints:int, numFlashes:int)
		{
			this._state = LightningBolt.INIT_STATE;
			this._shape = shape;
			this._points = new ArrayList();
			this._numPoints = numPoints;
			this._canFlash = true;
			this._numFlashes = numFlashes;
			this._time = 0;
		}
		
		public function get state():String { return this._state; }
		public function set state(state:String):void { this._state = state; }
		
		public function get shape():Shape { return this._shape; }
		public function set shape(shape:Shape):void
		{
			var container:DisplayObjectContainer = this._shape.parent;
			container.removeChild(this._shape);
			container.addChild(shape);
			this._shape = shape;
		}
		
		public function get points():ArrayList { return this._points; }
		
		public function get numPoints():int { return this._numPoints; }
		public function set numPoints(number:int):void
		{
			this._numPoints = number;
			if(this._numPoints < 1) this._numPoints = 1;
		}
		
		public function get canFlash():Boolean { return this._canFlash; }
		public function set canFlash(boolean:Boolean):void { this._canFlash = boolean; }
		
		public function get numFlashes():int { return this._numFlashes; }
		public function set numFlashes(number:int):void
		{
			this._numFlashes = number;
			if(this._numFlashes < 0) this._numFlashes = 0;
		}
		
		public function get time():Number { return this._time; }
		public function set time(number:Number):void { this._time = number; }
	}
}