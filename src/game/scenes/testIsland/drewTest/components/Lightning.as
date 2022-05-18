package game.scenes.testIsland.drewTest.components
{
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Component;
	
	import game.scenes.testIsland.drewTest.classes.LightningBolt;
	import game.util.Utils;
	
	import org.as3commons.collections.ArrayList;

	public class Lightning extends Component
	{
		private var _box:Rectangle;
		private var _audioChance:Number;
		private var _wait:Point;
		private var _time:Number;
		
		private var _bolts:ArrayList;
		private var _minBolts:int;
		private var _maxBolts:int;
		private var _minBoltPoints:int;
		private var _maxBoltPoints:int;
		private var _minFlashes:int;
		private var _maxFlashes:int;
		private var _dead:Vector.<LightningBolt>;
		
		public function Lightning(box:Rectangle, minWait:Number = 2, maxWait:Number = 4, minBolts:int = 1, maxBolts:int = 3)
		{
			this._box = box;
			this._audioChance = 1;
			this._wait = new Point(minWait, maxWait);
			this._time = Utils.randNumInRange(this._wait.x, this._wait.y);
			
			this._bolts = new ArrayList();
			this._minBolts = minBolts;
			this._maxBolts = maxBolts;
			this._minBoltPoints = 8;
			this._maxBoltPoints = 12;
			this._minFlashes = 0;
			this._maxFlashes = 2;
			this._dead = new Vector.<LightningBolt>();
		}
		
		public function get box():Rectangle { return this._box; }
		public function set box(box:Rectangle):void { this._box = box; }
		
		public function get audioChance():Number { return this._audioChance; }
		public function set audioChance(number:Number):void { this._audioChance = number; }
		
		public function get minWait():Number { return this._wait.x; }
		public function set minWait(min:Number):void { this._wait.x = min; }
		
		public function get maxWait():Number { return this._wait.y; }
		public function set maxWait(max:Number):void { this._wait.y = max; }
		
		public function get bolts():ArrayList { return this._bolts; }
		public function get dead():Vector.<LightningBolt> { return this._dead; }
		
		public function get minBolts():int { return this._minBolts; }
		public function set minBolts(min:int):void
		{ this._minBolts = min; if(this._minBolts < 0) this._minBolts = 0; }
		
		public function get maxBolts():int { return this._maxBolts; }
		public function set maxBolts(max:int):void
		{ this._maxBolts = max; if(this._maxBolts < 0) this._maxBolts = 0;}
		
		public function get minBoltPoints():int { return this._minBoltPoints; }
		public function set minBoltPoints(min:int):void
		{ this._minBoltPoints = min; if(this._minBoltPoints < 1) this._minBoltPoints = 1; }
		
		public function get maxBoltPoints():int { return this._maxBoltPoints; }
		public function set maxBoltPoints(max:int):void
		{ this._maxBoltPoints = max; if(this._maxBoltPoints < 1) this._maxBoltPoints = 1; }
		
		public function get minFlashes():int { return this._minFlashes; }
		public function set minFlashes(min:int):void
		{ this._minFlashes = min; if(this._minFlashes < 0) this._minFlashes = 0; }
		
		public function get maxFlashes():int { return this._maxFlashes; }
		public function set maxFlashes(max:int):void
		{ this._maxFlashes = max; if(this._maxFlashes < 0) this._maxFlashes = 0; }
		
		public function get time():Number { return this._time; }
		public function set time(number:Number):void { this._time = number; }
	}
}