package engine.components
{
	import flash.geom.Point;
	
	import ash.core.Component;
	
	public class Motion extends Component
	{
		public var pause:Boolean = false;
		
		public var totalVelocity:Point = new Point(0, 0);
        public var velocity:Point = new Point(0, 0);
		public var lastVelocity:Point = new Point(0,0);
        public var acceleration:Point = new Point(0, 0);
		public var previousAcceleration:Point = new Point(0, 0);
		public var friction:Point = new Point(0, 0);
		public var maxVelocity:Point = new Point(Infinity, Infinity);
		public var minVelocity:Point = new Point(0, 0);
		private var _rotationVelocity:Number = 0;
		public var rotationMaxVelocity:Number = Infinity;
		public var rotationMinVelocity:Number = 0;
		private var _rotationAcceleration:Number = 0;
		public var rotationFriction:Number = 0;
		public var parentRotationVelocity:Number = 0;
		public var parentVelocity:Point;
		public var parentAcceleration:Point;
		public var parentFriction:Point;
		public var parentMotionFactor:Number = 1;
		/**
		 * When bouncing if velocity drop below restVelocity, motion ceases
		 */
		public var restVelocity:Number = 0;	// 
		/**
		 * Holds the previous values of the x and y properties for interpolation.
		 */
		public var previousX:Number;
		public var previousY:Number;
		public var previousRotation:Number;
		public var _x:Number;
		public var _y:Number;
		public var _rotation:Number;
		public var _updateX:Boolean = false;
		public var _updateY:Boolean = false;
		public var _updateRotation:Boolean = false;
		public var _updateRotationMotion:Boolean = false;
		public var smoothPosition:Boolean = true;
		
		[Inline]
		final public function get rotationAcceleration():Number { return _rotationAcceleration; }
		[Inline]
        final public function get rotationVelocity():Number { return _rotationVelocity; }
		[Inline]
		final public function set rotationAcceleration(rotationAcceleration:Number):void { _rotationAcceleration = rotationAcceleration; _updateRotationMotion = true; }
		[Inline]
		final public function set rotationVelocity(rotationVelocity:Number):void { _rotationVelocity = rotationVelocity; _updateRotationMotion = true; }
		[Inline]
		final public function set x(x:Number):void { _x = x; _updateX = true; }
		[Inline]
		final public function get x():Number { return(_x); }	
		[Inline]
		final public function set y(y:Number):void { _y = y; _updateY = true; }
		[Inline]
		final public function get y():Number { return(_y); }	
		[Inline]
		final public function set rotation(rotation:Number):void { _rotation = rotation; _updateRotation = true; }
		[Inline]
		final public function get rotation():Number { return(_rotation); }
		
		public function zeroMotion( axis:String = null ):void
		{
			if(axis == null || axis == "x")
			{
				acceleration.x = velocity.x = previousAcceleration.x = totalVelocity.x = 0;
			}
			
			if(axis == null || axis == "y")
			{
				acceleration.y = velocity.y = previousAcceleration.y = totalVelocity.y = 0;
			}	
			
			if(axis == null || axis == "rotation")
			{
				rotationAcceleration = rotationVelocity = previousRotation = rotation = 0;
			}
		}
		
		public function zeroAcceleration( axis:String = null ):void
		{
			if(axis == null || axis == "x")
			{
				acceleration.x = previousAcceleration.x = 0;
			}
			
			if(axis == null || axis == "y")
			{
				acceleration.y = previousAcceleration.y = 0;
			}
		}
	}
}
