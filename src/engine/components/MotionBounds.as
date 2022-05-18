package engine.components
{
	import flash.geom.Rectangle;
	import ash.core.Component;

	/**
	 * @see game.systems.BoundsChecksystem 
	 */	
	public class MotionBounds extends Component
	{
		public function MotionBounds( rect:Rectangle = null )
		{
			if ( rect )
			{
				box = rect;
			}
		}
		
		/**
		 * This use of a <code>Rectangle</code> is unorthodox and confusing. It should probably be just an
		 * object with four properies. Although <code>box.left</code> and <code>box.top</code>
		 * do correspond with an entity's West and North spatial limits, <code>box.right</code> and
		 * <code>box.bottom</code> do not. For <code>BoundCheckSystem</code> to work,
		 * <code>box</code> must be initialized with values for <code>width</code> and <code>height</code>
		 * which represent the screen coordinates of the entity's East and South spatial limits.
		 * 
		 * <p>To make sense of this mixup, consider a 1000 by 1000 pixel stage. A one-dimensional entity needs
		 * to be constrained inside a margin of 50 pixels on each side. The "box" which limits its position is
		 * a rectangle {left:50, top:50, width:900, height:900}. This makes sense at first glance, but do not
		 * pass this rectangle to <code>MotionBounds'</code> constructor. The <code>box</code> that <code>MotionBounds</code>
		 * wants is the rectangle {left:50, top:50, width:950, height:950}.</p>
		 * 
		 * <p>An <code>Edges</code> object has been created to help improve things.</p>
		 * 
		 * <p>This class should be re-written for clarity and consistency and <strong>all</strong> client code
		 * should be modified to accomodate those changes.</p>
		 * 
		 * @see engine.data.Edges
		 */		
		public var box:Rectangle;

		/**
		 * <code>BoundCheckSystem</code> sets this collision flag to <code>false</code> when the <code>spatial.y</code> of an entity is greater than <code>box.y</code>,
		 * indicating that it is farther South on the screen and unconstrained in its upward motion.
		 * It will be set to <code>true</code> when an entity has reached or exceeded its topmost valid <code>spatial.y</code> position and is 'pinned'.
		 * Unless its <code>reposition</code> is <code>true</code>, <code>BoundCheckSystem</code> will limit its <code>spatial.y</code> to the value of <code>box.top</code>.
		 * 
		 * <p>Think of this flag as a "hitting the ceiling" value</p>
		 * 
		 * @default false
		 */		
		public var top:Boolean = false;

		/**
		 * <code>BoundCheckSystem</code> sets this collision flag to <code>false</code> when the <code>spatial.y</code> of an entity is less than <code>box.height</code>,
		 * indicating that it is farther North on the screen and unconstrained in its downward motion.
		 * It will be set to <code>true</code> when an entity has reached or exceeded its bottommost valid <code>spatial.y</code> position and is 'pinned'.
		 * Unless its <code>reposition</code> is <code>true</code>, <code>BoundCheckSystem</code> will limit its <code>spatial.y</code> to the value of <code>box.height</code>.
		 * 
		 * <p>Think of this flag as a "bottoming out" value</p>
		 * 
		 * @default false
		 */		
		public var bottom:Boolean = false;

		/**
		 * <code>BoundCheckSystem</code> sets this collision flag to <code>false</code> when the <code>spatial.x</code> of an entity is less than <code>box.x</code>,
		 * indicating that it is farther West on the screen and unconstrained in its leftward motion.
		 * It will be set to <code>true</code> when an entity has reached or exceeded its leftmost valid <code>spatial.x</code> position and is 'pinned'.
		 * Unless its <code>reposition</code> is <code>true</code>, <code>BoundCheckSystem</code> will limit its <code>spatial.x</code> to the value of <code>box.x</code>.
		 * 
		 * <p>Think of this flag as a "hitting the left wall" value</p>
		 * 
		 * @default false
		 */		
		public var left:Boolean = false;

		/**
		 * <code>BoundCheckSystem</code> sets this collision flag to <code>false</code> when the <code>spatial.x</code> of an entity is less than <code>box.width</code>,
		 * indicating that it is farther East on the screen and unconstrained in its rightward motion.
		 * It will be set to <code>true</code> when an entity has reached or exceeded its rightmost valid <code>spatial.x</code> position and is 'pinned'.
		 * Unless its <code>reposition</code> is <code>true</code>, <code>BoundCheckSystem</code> will limit its <code>spatial.x</code> to the value of <code>box.width</code>.
		 * 
		 * <p>Think of this flag as a "hitting the right wall" value</p>
		 * 
		 * @default false
		 */		
		public var right:Boolean = false;

		/**
		 * When set, this flag tells <code>BoundCheckSystem</code> that it is permitted
		 * to alter the entity's <code>Spatial</code> properties when it has reached
		 * or exceeded its constraints. If you set this to <code>false</code>, <code>BoundCheckSystem</code>
		 * will still set the appropriate collision flag, but allow the entity to exceed its constraints.
		 * 
		 * @default true
		 */		
		public var reposition:Boolean = true;
	}
}