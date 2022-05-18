package game.scenes.testIsland.drewTest.classes
{
	import flash.display.DisplayObjectContainer;
	import flash.display.Shape;
	import flash.geom.Point;
	
	import game.util.Utils;

	public class TornadoParticle
	{
		private var _shape:Shape;
		private var _isForward:Boolean;
		
		private var _rotation:Number;
		private var _velocity:Point;
		
		private var _time:Number;
		
		public function TornadoParticle(shape:Shape, velocity:Point = null)
		{
			this._shape = shape;
			this._rotation = Utils.randNumInRange(-100, 100);
			this._velocity = new Point(Utils.randNumInRange(1, 1.5), Utils.randNumInRange(-100, -50));
			this._time = Utils.randNumInRange(0, Math.PI * 2);
			
			if(Math.random() > 0.5) this.isForward = true;
			else this.isForward = false;
		}
		
		public function get shape():Shape { return this._shape; }
		public function set shape(shape:Shape):void
		{
			var container:DisplayObjectContainer = this._shape.parent;
			container.removeChild(this._shape);
			container.addChild(shape);
			this._shape = shape;
		}
		
		public function get isForward():Boolean { return this._isForward; }
		public function set isForward(boolean:Boolean):void { this._isForward = boolean; }
		
		public function get rotation():Number { return this._rotation; }
		public function set rotation(number:Number):void { this._rotation = number; }
		
		public function get velocityX():Number { return this._velocity.x; }
		public function set velocityX(x:Number):void { this._velocity.x = x; }
		
		public function get velocityY():Number { return this._velocity.y; }
		public function set velocityY(y:Number):void { this._velocity.y = y; }
		
		public function get time():Number { return this._time; }
		public function set time(time:Number):void { this._time = time; }
	}
}