package engine.components
{
	import ash.core.Component;

	/**
	 * The <code>SpatialOffset</code> component provides a means
	 * of applying an additive modifier to the basic positional
	 * properties (<code>x</code>, <code>y</code> and <code>rotation</code>)
	 * of an <code>Entity</code>'s core <code>Spatial</code>.
	 * 
	 * <p>This can be useful for causing two <code>Entities</code> to
	 * move in unison, but separated by a short distance. The effect
	 * can be achieved by endowing each <code>Entity</code> with a reference
	 * to the same core <code>Spatial</code> component. Each "companion"
	 * <code>Entity</code> receives a <code>SpatialOffset</code> component
	 * which defines the current modifiers.</p>
	 * 
	 * <p>Although the <code>RenderSystem</code> is the primary consumer of
	 *  <code>SpatialOffsets</code>, new <code>Systems</code> could implement
	 * methods to dynamically alter the modifiers. A departing/returning loop could be
	 * achieved by cleverly altering the <code>x</code> and <code>y</code> properties.</p>
	 * 
	 * This value will be added to a Spatial components when being applied to a Display position in RenderSystem, but will NOT accumulate like SpatialAddition.
	 * 
	 */	
	public class SpatialOffset extends Component
	{
		
		public function SpatialOffset( x:Number = 0, y:Number = 0, rotation:Number = 0 )
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
		public var _baseX:Number = 0;  // the base offsets to apply to x and y
		public var _baseY:Number = 0;
		public var _invalidate:Boolean = false;
	}
}
