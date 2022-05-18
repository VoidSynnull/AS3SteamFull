package engine.components
{	
	import ash.core.Component;

	/**
	 * Spatial is one of the fundamental components, used by every
	 * Entity which has a position in gamespace and/or needs to be drawn onscreen.
	 * 
	 * @see engine.components.Display
	 * @see engine.systems.RenderSystem
	 */	
	public class Spatial extends Component
	{
		public function Spatial(initialX:Number=NaN, initialY:Number=NaN) 
		{
			this.x = initialX;
			this.y = initialY;
		}
		/**
		 * The horizontal location of this component's <code>Entity</code>. Expressed in pixels, decimals are rounded to the nearest .05 when Flash Player calculates pixel positions.
		 * 
		 * <p>The <code>RenderSystem</code> will initialize this with the <code>x</code> value of a paired <code>Display</code> component as soon as the owning <code>Entity</code> is added to the <code>Nodelist</code> of <code>RenderNodes</code>. If there is no paired <code>Display</code>, it is initialized to zero.</p>
		 * 
		 * @default		NaN
		 */		
		[Inline]
		final public function set x(x:Number):void { _x = x; _updateX = true; _invalidate = true; }
		[Inline]
		final public function get x():Number { return(_x); }
		/**
		 * The vertical location of this component's <code>Entity</code>.  Expressed in pixels, decimals are rounded to the nearest .05 when Flash Player calculates pixel positions.
		 * 
		 * <p>The <code>RenderSystem</code> will initialize this with the <code>y</code> value of a paired <code>Display</code> component as soon as the owning <code>Entity</code> is added to the <code>Nodelist</code> of <code>RenderNodes</code>. If there is no paired <code>Display</code>, it is initialized to zero.</p>
		 * 
		 * @default		NaN
		 */		
		[Inline]
		final public function set y(y:Number):void { _y = y; _updateY = true; _invalidate = true; }
		[Inline]
		final public function get y():Number { return(_y); }
		
		/**
		 * Indicates the horizontal scale (percentage) of the object as applied from the registration point. The default registration point is (0,0). 1.0 equals 100% scale. 
		 * 
		 * <p>The <code>RenderSystem</code> will initialize this with the <code>scaleX</code> value of a paired <code>Display</code> component as soon as the owning <code>Entity</code> is added to the <code>Nodelist</code> of <code>RenderNodes</code>. If there is no paired <code>Display</code>, it is initialized to 1.0.</p>
		 * 
		 * <p>Setting the scaleX of a <code>Spatial</code> to a negative value causes a paired <code>Display</code> component to flip horizontally.</p>
		 * 
		 * @default		NaN		
		 */		
		[Inline]
		final public function set scaleX(scaleX:Number):void { _scaleX = scaleX; _invalidate = true; }
		[Inline]
		final public function get scaleX():Number { return(_scaleX); }
		
		/**
		 * Indicates the vertical scale (percentage) of the object as applied from the registration point. The default registration point is (0,0). 1.0 equals 100% scale. 
		 * 
		 * <p>The <code>RenderSystem</code> will initialize this with the <code>scaleY</code> value of a paired <code>Display</code> component as soon as the owning <code>Entity</code> is added to the <code>Nodelist</code> of <code>RenderNodes</code>. If there is no paired <code>Display</code>, it is initialized to zero.</p>
		 * 
		 * <p>Setting the scaleY of a <code>Spatial</code> to a negative value causes a paired <code>Display</code> component to flip vertically.</p>
		 * 
		 * @default		NaN		
		 */	
		[Inline]
		final public function set scaleY(scaleY:Number):void { _scaleY = scaleY; _invalidate = true; }
		[Inline]
		final public function get scaleY():Number { return(_scaleY); }
		
		/**
		 * The rotation about the z-axis of this component's Entity. Expressed in degrees.
		 * Values outside the 'nominal' range of rotation (-180 to 180 degrees) are coerced
		 * to this range by the <code>RenderSystem</code> unless this component is paired
		 * with a <code>Display</code> which has been marked <code>isStatic</code>.
		 * 
		 * <p>The <code>RenderSystem</code> will initialize this with the <code>rotation</code> value of a paired <code>Display</code> component as soon as the owning <code>Entity</code> is added to the <code>Nodelist</code> of <code>RenderNodes</code>. If there is no paired <code>Display</code>, it is initialized to 1.0.</p>
		 * 
		 * @default		NaN		
		 */		
		[Inline]
		final public function set rotation(rotation:Number):void { _rotation = rotation; _updateRotation = true; _invalidate = true; }
		[Inline]
		final public function get rotation():Number { return(_rotation); }
		[Inline]
		final public function set width(width:Number):void { _width = width; _updateWidth = true; _invalidate = true; }
		[Inline]
		final public function set height(height:Number):void { _height = height; _updateHeight = true; _invalidate = true; }

		/**
		 * This is a scale shortcut method...pretty char specific TODO - move this.
		 */		
		[Inline]
		final public function set scale(scale:Number):void 
		{ 
			_scale = scale;
			
			if(this.scaleX >= 0 || isNaN(this.scaleX))
			{
				this.scaleX = scale;
			}
			else
			{
				this.scaleX = -scale;
			}
			
			if(this.scaleY >= 0 || isNaN(this.scaleY))
			{
				this.scaleY = scale;
			}
			else
			{
				this.scaleY = -scale;
			}
			
			_invalidate = true;
		}

		/**
		 * The width, in pixels, of this component's <code>Entity</code>.
		 * 
		 * <p>Getting the <code>width</code> property of a <code>Spatial</code> component returns
		 * the value stored in its internal variable. If this component's <code>updateWidth</code>
		 * property if <code>true</code>, a paired <code>Display</code> component's <code>width</code>
		 * may contain a different, stale value until <code>RenderSystem</code> runs its next
		 * <code>update()</code>, unless this component is paired with a
		 * <code>Display</code> which has been marked <code>isStatic</code>.</p>
		 * 
		 * <p>Setting the <code>width</code> property of a component sets an internal flag
		 * which marks the property as 'dirty'. <code>RenderSystem</code> will clear this
		 * flag during its next <code>update</code> after it has applied the <code>width</code>
		 * to a paired <code>Display</code> component and updated this component's <code>scaleX</code>
		 * property, unless this component is paired with a
		 * <code>Display</code> which has been marked <code>isStatic</code>.</p>
		 */		
		[Inline]
		final public function get width():Number { return(_width); }

		/**
		 * The height, in pixels, of this component's <code>Entity</code>.
		 * 
		 * <p>Getting the <code>height</code> property of a <code>Spatial</code> component returns
		 * the value stored in its internal variable. If this component's <code>updateHeight</code>
		 * property if <code>true</code>, a paired <code>Display</code> component's <code>height</code>
		 * may contain a different, stale value until <code>RenderSystem</code> runs its next
		 * <code>update()</code>, unless this component is paired with a
		 * <code>Display</code> which has been marked <code>isStatic</code>.</p>
		 * 
		 * <p>Setting the <code>height</code> property of a component sets an internal flag
		 * which marks the property as 'dirty'. <code>RenderSystem</code> will clear this
		 * flag during its next <code>update</code> after it has applied the <code>height</code>
		 * to a paired <code>Display</code> component and updated this component's <code>scaleY</code>
		 * property, unless this component is paired with a
		 * <code>Display</code> which has been marked <code>isStatic</code>.</p>
		 */		
		[Inline]
		final public function get height():Number { return(_height); }

		/**
		* The <code>scale</code> property of a component is provided as a convenience for
		* establishing a uniform scaling in both the <code>x</code> and <code>y</code> axes.
		* 
		* <p>When reading this property, it is possible to receive a value of <code>NaN</code>
		* if no value has yet been assigned to <code>scale</code>.</p>
		*
		* @see engine.components.Spatial.scaleX
		* @see engine.components.Spatial.scaleY
		*/
		[Inline]
		final public function get scale():Number { return(_scale); }

		/**
		 * Restores all the properties of a Spatial Component
		 * to their default values. 
		 * 
		 */		
		[Inline]
		final public function reset():void 
		{
			x = y = rotation = 0;
			scale = 1;
			_width = _height = NaN;
			_updateHeight = _updateWidth = false;
			_invalidate = true;
		}

		private var _scaleX:Number;
		private var _scaleY:Number;
		private var _width:Number;
		private var _height:Number;
		private var _scale:Number = 1;
		public var _x:Number;
		public var _y:Number;
		public var _rotation:Number;	
		public var _updateWidth:Boolean = false;	
		public var _updateHeight:Boolean = false;
		public var _updateX:Boolean = false;
		public var _updateY:Boolean = false;
		public var _updateRotation:Boolean = false;
		public var _invalidate:Boolean = true;
	}
}
