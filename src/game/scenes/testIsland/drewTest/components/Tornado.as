package game.scenes.testIsland.drewTest.components
{
	import flash.display.Shape;
	import flash.geom.Point;
	
	import ash.core.Component;
	
	import game.scenes.testIsland.drewTest.classes.TornadoParticle;
	
	import org.as3commons.collections.ArrayList;

	public class Tornado extends Component
	{
		private var _resetCircles:Boolean;
		private var _resetParticles:Boolean;
		
		private var _startRadius:Number;
		private var _offset:Point;
		
		private var _circles:ArrayList;
		private var _numCircles:int;
		private var _circleColor:uint;
		
		private var _particles:ArrayList;
		private var _numParticles:int;
		private var _particleColors:Array;
		
		private var _particleOffsetX:Number;
		private var _dead:Vector.<TornadoParticle>;
		
		private var _speed:Number;
		private var _delay:Number;
		private var _magnitude:Number;
		private var _time:Number;
		
		public function Tornado(startRadius:Number = 100, offsetX:Number = 15, offsetY:Number = 50, numCircles:uint = 10, numParticles:uint = 200)
		{
			this._resetCircles = true;
			this._resetParticles = true;
			
			this._startRadius = startRadius;
			this._offset = new Point(offsetX, offsetY);
			
			this._circles = new ArrayList();
			this._numCircles = numCircles;
			this._circleColor = 0x000000;
			
			this._particles = new ArrayList();
			this._numParticles = numParticles;
			this._particleColors = [0x111111, 0x333333, 0x552200, 0x003300]; //Gray, Gray, Brown, Green
			
			this._particleOffsetX = 10;
			this._dead = new Vector.<TornadoParticle>();
			
			this._speed = 2.5;
			this._delay = 0.005;
			this._magnitude = 0.35;
			this._time = 0;
		}
		
		public function get resetCircles():Boolean { return this._resetCircles; }
		public function set resetCircles(boolean:Boolean):void { this._resetCircles = boolean; }
		
		public function get resetParticles():Boolean { return this._resetParticles; }
		public function set resetParticles(boolean:Boolean):void { this._resetParticles = boolean; }
		
		public function get startRadius():Number { return this._startRadius; }
		public function set startRadius(radius:Number):void { this._startRadius = radius; this._resetCircles = true; }
		
		public function get circleOffsetX():Number { return this._offset.x; }
		public function set circleOffsetX(x:Number):void { this._offset.x = x; this._resetCircles = true; }
		
		public function get circleOffsetY():Number { return this._offset.y; }
		public function set circleOffsetY(y:Number):void { this._offset.y = y; this._resetCircles = true; }
		
		public function get numCircles():int { return this._numCircles; }
		public function set numCircles(number:int):void
		{ this._numCircles = number; if(this._numCircles < 1) this._numCircles = 1; this._resetCircles = true; }
		
		public function get circleColor():uint { return this._circleColor; }
		public function set circleColor(color:uint):void { this._circleColor = color; this._resetCircles = true; }
		
		public function get numParticles():int { return this._numParticles; }
		public function set numParticles(number:int):void
		{ this._numParticles = number; if(this._numParticles < 0) this._numParticles = 0; }
		
		public function get particleColors():Array { return this._particleColors; }
		public function set particleColors(colors:Array):void { this._particleColors = colors; }
		
		public function get particleOffsetX():Number { return this._particleOffsetX; }
		public function set particleOffsetX(x:Number):void { this._particleOffsetX = x; }
		
		public function get height():Number { var shape:Shape = this._circles.last; return -shape.y + shape.height * 0.5; }
		public function get width():Number { var shape:Shape = this._circles.last; return shape.width; }
		
		public function get circles():ArrayList { return this._circles; }
		public function get particles():ArrayList { return this._particles; }
		public function get dead():Vector.<TornadoParticle> { return this._dead; }
		
		public function get speed():Number { return this._speed; }
		public function set speed(number:Number):void { this._speed = number; }
		
		public function get delay():Number { return this._delay; }
		public function set delay(number:Number):void { this._delay = number; }
		
		public function get magnitude():Number { return this._magnitude; }
		public function set magnitude(number:Number):void { this._magnitude = number; }
		
		public function get time():Number { return this._time; }
		public function set time(number:Number):void { this._time = number; }
	}
}