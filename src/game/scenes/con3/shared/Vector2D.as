package game.scenes.con3.shared
{
	import flash.geom.Point;
	
	/**
	 * @author Drew Martin
	 */
	public class Vector2D
	{
		protected var _x:Number = 0;
		protected var _y:Number = 0;
		
		public function Vector2D(x:Number = 0, y:Number = 0)
		{
			this.x = x;
			this.y = y;
		}
		
		public function toString():String
		{
			return "[Vector2D (" + this._x + "," + this._y + ")]";
		}
		
		public function get x():Number { return this._x; }
		public function set x(x:Number):void
		{
			if(isFinite(x))
			{
				this._x = x;
			}
		}
		
		public function get y():Number { return this._y; }
		public function set y(y:Number):void
		{
			if(isFinite(y))
			{
				this._y = y;
			}
		}
		
		public function set(vector:Vector2D):Vector2D
		{
			return this.setXY(vector._x, vector._y);
		}
		
		public function setPolar(length:Number, radians:Number):Vector2D
		{
			return this.setXY(length * Math.cos(radians), length * Math.sin(radians));
		}
		
		public function setXY(x:Number, y:Number):Vector2D
		{
			this.x = x;
			this.y = y;
			return this;
		}
		
		public function add(vector:Vector2D, scalar:Number = 1):Vector2D
		{
			return this.addXY(vector._x, vector._y, scalar);
		}
		
		public function addPolar(length:Number, radians:Number, scalar:Number = 1):Vector2D
		{
			return this.addXY(length * Math.cos(radians), length * Math.sin(radians), scalar);
		}
		
		public function addXY(x:Number, y:Number, scalar:Number = 1):Vector2D
		{
			this.x += x * scalar;	
			this.y += y * scalar;
			return this;
		}
		
		public function subtract(vector:Vector2D, scalar:Number = 1):Vector2D
		{
			return this.subtractXY(vector._x, vector._y, scalar);
		}
		
		public function subtractPolar(length:Number, radians:Number, scalar:Number = 1):Vector2D
		{
			return this.subtractXY(length * Math.cos(radians), length * Math.sin(radians), scalar);
		}
		
		public function subtractXY(x:Number, y:Number, scalar:Number = 1):Vector2D
		{
			this.x -= x * scalar;	
			this.y -= y * scalar;
			return this;
		}
		
		public function multiply(vector:Vector2D):Vector2D
		{
			return this.multiplyXY(vector._x, vector._y);
		}
		
		public function multiplyPolar(length:Number, radians:Number):Vector2D
		{
			return this.multiplyXY(length * Math.cos(radians), length * Math.sin(radians));
		}
		
		public function multiplyXY(x:Number, y:Number):Vector2D
		{
			this.x *= x;	
			this.y *= y;
			return this;
		}
		
		public function divide(vector:Vector2D):Vector2D
		{
			return this.divideXY(vector._x, vector._y);
		}
		
		public function dividePolar(length:Number, radians:Number):Vector2D
		{
			return this.divideXY(length * Math.cos(radians), length * Math.sin(radians));
		}
		
		public function divideXY(x:Number, y:Number):Vector2D
		{
			this.x /= x;
			this.y /= y;
			return this;
		}
		
		public function get degrees():Number { return this.radians * (180 / Math.PI); }
		public function get radians():Number { return Math.atan2(this._y, this._x); }
		
		public function addDegrees(degrees:Number):Vector2D
		{
			return this.setDegrees(this.degrees + degrees);
		}
		
		public function addRadians(radians:Number):Vector2D
		{
			return this.setRadians(this.radians + radians);
		}
		
		public function setDegrees(degrees:Number):Vector2D
		{
			return this.setRadians(degrees * (Math.PI / 180));
		}
		
		public function setRadians(radians:Number):Vector2D
		{
			const length:Number = this.length;
			this.x = length * Math.cos(radians);
			this.y = length * Math.sin(radians);
			return this;
		}
		
		public function get length():Number { return Math.sqrt(this.lengthSquared); }
		public function get lengthSquared():Number { return this._x * this._x + this._y * this._y; }
		
		public function reflect(normal:Vector2D):Vector2D
		{
			return this.reflectXY(normal._x, normal._y);
		}
		
		public function reflectXY(normalX:Number, normalY:Number):Vector2D
		{
			const dot2:Number = 2 * this.dotXY(normalX, normalY);
			this.x -= normalX * dot2;
			this.y -= normalY * dot2;
			return this;
		}
		
		public function equals(vector:Vector2D):Boolean
		{
			return this.equalsXY(vector._x, vector._y);
		}
		
		public function equalsXY(x:Number, y:Number):Boolean
		{
			return this._x == x && this._y == y;
		}
		
		public function dot(vector:Vector2D):Number
		{
			return this.dotXY(vector._x, vector._y);
		}
		
		public function dotXY(x:Number, y:Number):Number
		{
			return this._x * x + this._y * y;
		}
		
		public function cross(vector:Vector2D):Number
		{
			return this.crossXY(vector._x, vector._y);
		}
		public function crossXY(x:Number, y:Number):Number
		{
			return this._x * x - this._y * y;
		}
		
		public function rotate(vector:Vector2D, radians:Number):Vector2D
		{
			return this.rotateXY(vector._x, vector._y, radians);
		}
		
		public function rotateXY(x:Number, y:Number, radians:Number):Vector2D
		{
			const cosine:Number 	= Math.cos(radians);
			const sine:Number 		= Math.sin(radians);
			this.x 					-= x;
			this.y 					-= y;
			const offsetX:Number 	= this._x * cosine - this._y * sine;
			const offsetY:Number 	= this._x * sine + this._y * cosine;
			this.x 					= x + offsetX;
			this.y 					= y + offsetY;
			return this;
		}
		
		public function clone():Vector2D
		{
			return new Vector2D(this._x, this._y);
		}
		
		public function zero():Vector2D
		{
			this.x = 0;
			this.y = 0;
			return this;
		}
		
		public function invert():Vector2D
		{
			this.x = -this._x;
			this.y = -this._y;
			return this;
		}
		
		public function distance(vector:Vector2D):Number
		{
			return this.distanceXY(vector._x, vector._y);
		}
		
		public function distanceXY(x:Number, y:Number):Number
		{
			return Math.sqrt(this.distanceSquaredXY(x, y));
		}
		
		public function distanceSquared(vector:Vector2D):Number
		{
			return this.distanceSquaredXY(vector._x, vector._y);
		}
		
		public function distanceSquaredXY(x:Number, y:Number):Number
		{
			const deltaX:Number = this._x - x;
			const deltaY:Number = this._y - y;
			return deltaX * deltaX + deltaY * deltaY;
		}
		
		public function radiansBetween(vector:Vector2D):Number
		{
			return this.radiansBetweenXY(vector._x, vector._y);
		}
		
		public function radiansBetweenXY(x:Number, y:Number):Number
		{
			return Math.atan2(y - this._y, x - this._x);
		}
		
		public function degreesBetween(vector:Vector2D):Number
		{
			return this.degreesBetweenXY(vector._x, vector._y);
		}
		
		public function degreesBetweenXY(x:Number, y:Number):Number
		{
			return Math.atan2(y - this._y, x - this._x) * (180 / Math.PI);
		}
		
		public function normalize(length:Number = 1):Vector2D
		{
			const ratio:Number = Math.abs(length) / this.length;
			this.x *= ratio;
			this.y *= ratio;
			return this;
		}
		
		public function perpendicularLeft():Vector2D
		{
			const x:Number 	= this._x;
			this.x 			= this._y;
			this.y 			= -x;
			return this;
		}
		
		public function perpendicularRight():Vector2D
		{
			const x:Number 	= this._x;
			this.x 			= -this._y;
			this.y 			= x;
			return this;
		}
		
		public function clamp(min:Number = 0, max:Number = Number.MAX_VALUE):Vector2D
		{
			const lengthSquared:Number = this.lengthSquared;
			if(lengthSquared < min * min)
			{
				this.normalize(min);
			}
			else if(lengthSquared > max * max)
			{
				this.normalize(max);
			}
			return this;
		}
		
		public function swap(vector:Vector2D):Vector2D
		{
			const x:Number 	= vector._x;
			const y:Number 	= vector._y;
			vector.x 		= this._x;
			vector.y 		= this._y;
			this.x 			= x;
			this.y 			= y;
			return this;
		}
		
		public function get point():Point { return new Point(this._x, this._y); }
	}
}