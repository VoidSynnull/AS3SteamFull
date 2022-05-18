package engine.components
{
	import ash.core.Component;

	/**
	 * This class adds its values to a Spatial components before being applied to a Display component's position for rendering.  It is similar to SpatialOffset except that its value accumulates.
	 * 
	 * @see engine.components.SpatialOffset
	 */	
	public class SpatialAddition extends Component
	{
		public function SpatialAddition( x:Number = 0, y:Number = 0, rotation:Number = 0 )
		{
			this.x = x;
			this.y = y;
			this.rotation = rotation;
		}
		
		[Inline]
		final public function set x(x:Number):void { _x = x; _invalidate = true; }
		[Inline]
		final public function get x():Number { return(_x); }	
		[Inline]
		final public function set y(y:Number):void { _y = y; _invalidate = true; }
		[Inline]
		final public function get y():Number { return(_y); }	
		[Inline]
		final public function set scaleX(scaleX:Number):void { _scaleX = scaleX; _invalidate = true; }
		[Inline]
		final public function get scaleX():Number { return(_scaleX); }
		[Inline]
		final public function set scaleY(scaleY:Number):void { _scaleY = scaleY; _invalidate = true; }
		[Inline]
		final public function get scaleY():Number { return(_scaleY); }	
		[Inline]
		final public function set rotation(rotation:Number):void { _rotation = rotation; _invalidate = true; }
		[Inline]
		final public function get rotation():Number { return(_rotation); }
		
		/**
		 * The amount to be added to the <code>x</code> value of a paired <code>Spatial</code> component.
		 * 
		 * @default	0
		 *  
		 */		
		public var _x:Number = 0;
		
		/**
		 * The amount to be added to the <code>y</code> value of a paired <code>Spatial</code> component.
		 * 
		 * @default	0
		 *  
		 */		
		public var _y:Number = 0;
		
		/**
		 * The amount, in degrees, to be added to the <code>rotation</code> value of a paired <code>Spatial</code> component.
		 * 
		 * @default	0
		 *  
		 */		
		public var _rotation:Number = 0;
		public var _scaleX:Number = 0;
		public var _scaleY:Number = 0;
		public var _invalidate:Boolean = false;

		public function reset():void {
			x = y = rotation = 0;
		}
	}
}
