package game.scenes.testIsland.drewTest.components
{
	import flash.geom.Rectangle;
	
	import ash.core.Component;
	
	import game.scenes.testIsland.drewTest.classes.WindLine;
	
	import org.as3commons.collections.ArrayList;
	
	public class Wind extends Component
	{
		private var _initializeWindLines:Boolean;
		
		private var _box:Rectangle;
		private var _isBlowingRight:Boolean;
		
		private var _minSpeed:Number;
		private var _maxSpeed:Number;
		
		private var _minWindLinePoints:int;
		private var _maxWindLinePoints:int;
		
		private var _numWindLines:int;
		private var _windLines:ArrayList;
		private var _dead:Vector.<WindLine>;
		
		public function Wind(box:Rectangle, numWindLines:int = 30)
		{
			this._initializeWindLines = true;
			
			this._box = box;
			this._isBlowingRight = true;
			
			this._minSpeed = 600;
			this._maxSpeed = 800;
			
			this._minWindLinePoints = 25;
			this._maxWindLinePoints = 50;
			
			this._numWindLines = numWindLines;
			this._windLines = new ArrayList();
			this._dead = new Vector.<WindLine>();
		}
		
		public function get initializeWindLines():Boolean { return this._initializeWindLines; }
		public function set initializeWindLines(boolean:Boolean):void { this._initializeWindLines = boolean; }
		
		public function get box():Rectangle { return this._box; }
		public function set box(box:Rectangle):void
		{
			if(box) this._box = box;
		}
		
		public function get minSpeed():Number { return this._minSpeed; }
		public function set minSpeed(min:Number):void
		{
			if(min < 1) min = 1;
			this._minSpeed = min;
		}
		
		public function get maxSpeed():Number { return this._maxSpeed; }
		public function set maxSpeed(max:Number):void
		{
			if(max < this._minSpeed) max = this._minSpeed;
			this._maxSpeed = max;
		}
		
		public function get minWindLinePoints():int { return this._minWindLinePoints; }
		public function set minWindLinePoints(min:int):void
		{
			if(min < 2) min = 2;
			this._minWindLinePoints = min;
		}
		
		public function get maxWindLinePoints():int { return this._maxWindLinePoints; }
		public function set maxWindLinePoints(max:int):void
		{
			if(max < this._minWindLinePoints) max = this._minWindLinePoints;
			this._maxWindLinePoints = max;
		}
		
		public function get numWindLines():int { return this._numWindLines; }
		public function set numWindLines(number:int):void
		{
			if(number < 0) number = 0;
			this._numWindLines = number;
		}
		
		public function get windLines():ArrayList { return this._windLines; }
		
		public function get dead():Vector.<WindLine> { return this._dead; }
	}
}