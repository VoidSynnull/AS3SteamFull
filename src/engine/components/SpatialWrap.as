package engine.components
{
	import ash.core.Component;

	/**
	 * The <code>SpatialWrap</code> component provides a means for wrapping layers.
	 * The size of the tiles must be equal or more than the viewport dimensions.
	 */	
	public class SpatialWrap extends Component
	{
		
		public function SpatialWrap( wrapX:int = 0, wrapY:int = 0 )
		{
			this.wrapX = wrapX;
			this.wrapY = wrapY;
			this.x = 0;
			this.y = 0;
		}

		/**
		 * The amount to be added/subtracted to the <code>x</code> value of a paired <code>Spatial</code> component.
		 * 
		 * @default	0
		 *  
		 */		
		public var wrapX:Number = 0;

		/**
		 * The amount to be added/subtracted to the <code>y</code> value of a paired <code>Spatial</code> component.
		 * 
		 * @default	0
		 *  
		 */		
		public var wrapY:Number = 0;

		/**
		 * The current wrap value added to the <code>x</code> value of a paired <code>Spatial</code> component.
		 * 
		 * @default	0
		 *  
		 */		
		public var x:Number = 0;
		
		/**
		 * The current wrap value added to the <code>y</code> value of a paired <code>Spatial</code> component.
		 * 
		 * @default	0
		 *  
		 */		
		public var y:Number = 0;
	}
}
