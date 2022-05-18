package game.components.ui
{
	import flash.geom.Rectangle;
	
	import ash.core.Component;
	
	import game.data.ui.RectSlot;
	import game.util.GeomUtils;
	
	import org.osflash.signals.Signal;

	public class GridControlScrollable extends Component
	{
		public function GridControlScrollable() 
		{
		}
		
		///////////////////////////// GRID /////////////////////////////
		
		/**
		 * Flag to lock grid movement
		 */
		public var lock:Boolean = false;
		
		/**
		 * Flag determining axis grid slides 
		 */
		public var isHorizontal:Boolean = true;
		
		/**
		 * Stores current percent, to test new percent against 
		 */
		public var currentPercent:Number;
		
		/**
		 * Dispatches when grid has shifted 
		 */
		public var didScroll:Signal = new Signal();
		
		/**
		 * Force grid to refresh positions
		 */
		public var refreshPositions:Boolean = false;
		
		/**
		 * Reset all slots
		 */
		public var resetSlots:Boolean = false;

		/**
		 * Dimension of grids active area
		 */
		public var _frameRect:Rectangle;
		public function get frameRect():Rectangle	{ return _frameRect; }
		public function set frameRect( rect:Rectangle):void	
		{ 
			_frameRect = rect;
			_frameVisibleRect = _frameRect.clone();
			if( _frameBuffer > 0 )
			{
				this.frameBuffer = _frameBuffer;
			}
		}

		/**
		 * Dimension of grids visible area, this accounts for any frame buffers.
		 */
		private var _frameVisibleRect:Rectangle;
		public function get frameVisibleRect():Rectangle	{ return _frameVisibleRect; }

		private var _frameBuffer:int = 0;
		public function set frameBuffer( value:int ):void	
		{ 
			value = Math.abs(value);
			_frameBuffer = value;
			
			if( _frameVisibleRect != null )
			{
				if( isHorizontal )
				{
					_frameVisibleRect.x -= _frameBuffer;
					_frameVisibleRect.width += _frameBuffer * 2;
				}
				else
				{
					_frameVisibleRect.y -= _frameBuffer;
					_frameVisibleRect.height += _frameBuffer * 2;
				}
			}
		}
		
		public var maxSlots:int;
		public var maxRows:int = 0 ;
		public var maxColumns:int = 0;
		
		/**
		 * Total length of grid along its sliding axis 
		 */
		private var _totalLength:Number = 0;
		public function get totalLength():Number	
		{ 
			return _totalLength; 
		}
		
		private var _rows:int = 0;
		public function get rows():int	{ return _rows; }
		public function set rows( value:int):void	
		{ 
			_rows = ( maxRows > 0 ) ? Math.min(value, maxRows) : value;
		}
		private var _columns:int = 0;
		public function get columns():int	{ return _columns; }
		public function set columns( value:int):void	
		{ 
			_columns = ( maxColumns > 0 ) ? Math.min(value, maxColumns) : value;
		}

		public var scrollSpeed:Number;
		public var maxScrollSpeed:Number;
		public var speed:Number;
		public var delta:Number = 0;
		public var minDelta:int = 5;

		public var jumpToTarget:Boolean = true;

		// may want the slot blueprint here as well
		private var _slotBuffer:Number = 0;
		public function get slotBuffer():Number	{ return _slotBuffer; }
		public function set slotBuffer( value:Number):void	
		{ 
			_slotBuffer = value;
			readjustRectangle();
		}
		
		private var _slotRect:Rectangle;			//dimensions of slot
		public function get slotRect():Rectangle	{ return _slotRect; }
		/**
		 * Set the dimensions of the slot, calculates adjusted size given current buffers
		 * @param rect
		 */
		public function set slotRect( rect:Rectangle ):void
		{
			if( _slotRect == null || !_slotRect.equals(rect) )
			{
				_slotRect = rect;
				readjustRectangle();
			}
		}
		private var _adjustedSlotRect:Rectangle;	//dimensions of slot, accounting for buffers
		/**
		 * Adjusted dimensions of slot, yaking into consideration buffers
		 * @return 
		 */
		public function get adjustedSlotRect():Rectangle	{ return _adjustedSlotRect; }
		
		private function readjustRectangle():void
		{
			if( _slotRect )
			{
				var halfBuffer:Number = _slotBuffer/2;
				var rect:Rectangle = _slotRect;
				rect.left += halfBuffer;
				rect.right += halfBuffer;
				rect.top += halfBuffer;
				rect.bottom += halfBuffer;
				_adjustedSlotRect = rect;
			}
		}
		
		/**
		 * Determines can scroll, by checking if the total slots exceed the frame dimension. 
		 * @return 
		 */
		public function get canScroll():Boolean 
		{
			return _totalLength > 0;
		}

		///////////////////////////// SLOTS /////////////////////////////

		public var _slots:Vector.<RectSlot> = new Vector.<RectSlot>();
		public function get slots():Vector.<RectSlot> { return _slots; }
		
		public function createSlots( numSlots:int, rows:Number = NaN, columns:Number = NaN, slotRect:Rectangle = null ):void 
		{
			// Clear slot list
			// TODO :: Could be more efficient about reusing RectMembers, for now I'm just creating new ones
			_slots.length = 0;	
			
			for (var i:int = 0; i < numSlots; i++) 	// create slots
			{
				_slots.push( new RectSlot( i ) );
			}
			
			reconfigSlots( rows, columns, slotRect ); 	// create & assign rectangles to slots
		}
		
		public function reconfigSlots( rows:Number = NaN, columns:Number = NaN, slotRect:Rectangle = null ):void 
		{
			if( !isNaN(rows) )		{ _rows = rows; }
			if( !isNaN(columns) )	{ _columns = columns; }
			if( slotRect != null )
			{
				this.slotRect = slotRect;
			}
			
			recalc();
			this.refreshPositions = true;	// force reposition
			this.currentPercent = 0;
			this.resetSlots = true;			// forces all slots to be deactivated and resized
		}
		
		///////////////////////////// SLOT CREATION /////////////////////////////
		
		/**
		 * Recalculate the grid.
		 */
		private function recalc():void 
		{
			var numSlots:int = _slots.length;
			var rects:Vector.<Rectangle> = GeomUtils.getGridRectsCondensed(numSlots, frameRect, slotRect, _columns, _rows, slotBuffer, isHorizontal);
			
			for (var i:int = 0; i < numSlots; i++) 
			{
				_slots[i].rect = rects[i];
			}
			
			_totalLength = getGridLength();
			_totalLength -= ( isHorizontal ) ? frameRect.width: frameRect.height;	// adjust for frame, keeps slots visible at end
		}
		
		/**
		 * Returns total length of slots, dependent on grid's orientation. 
		 * @return 
		 * 
		 */
		private function getGridLength():Number 
		{
			var maxLength:Number = -Number.MAX_VALUE;
			var startValue:Number = Number.MAX_VALUE;
			var i:uint = 0;
			var rect:Rectangle;
			if( isHorizontal )
			{
				for (i; i < _slots.length; i++) 
				{
					rect = _slots[i].rect;
					if (rect.left < startValue) 
					{
						startValue = rect.left;
					}
					if (rect.right > maxLength) 
					{
						maxLength = rect.right;
					}
				}
			}
			else
			{
				for (i; i < _slots.length; i++) 
				{
					rect = _slots[i].rect;
					if (rect.top < startValue) 
					{
						startValue = rect.top;
					}
					if (rect.bottom > maxLength) 
					{
						maxLength = rect.bottom;
					}
				}
			}
			return maxLength - startValue;
		}
		
		/**
		 * Updates positions of all slots by provided delta.
		 * Whether slots move along x or y axis is determined by isHorizontal variable.
		 * @param delta
		 * 
		 */
		public function shiftSlots( delta:Number ):void 
		{
			if ( delta != 0 ) 
			{
				var i:int = 0;
				if( isHorizontal )
				{
					for (i; i < _slots.length; i++) 
					{
						_slots[i].rect.offset(delta, 0);
					}
				}
				else
				{
					for (i; i < _slots.length; i++) 
					{
						_slots[i].rect.offset(0, delta);
					}
				}
			}
		}
		
		/**
		 * Determines if provided RectSlot is within the visible frame bounds.
		 * @param rectSlot
		 * @return 
		 */
		public function rectIsVisible( rect:Rectangle ):Boolean 
		{
			return frameVisibleRect.intersects(rect);
		}
		
		/**
		 * Return list of RectSlots currently visible within frame bounds  
		 * @return 
		 * 
		 */
		public function get visibleSlots():Vector.<RectSlot> 
		{
			var visibles:Vector.<RectSlot> = new Vector.<RectSlot>();
			var rectSlot:RectSlot;
			for (var i:int = 0; i < _slots.length; i++) 
			{
				rectSlot = _slots[i];
				if (rectIsVisible(rectSlot.rect)) 
				{
					visibles.push(rectSlot);
				}
			}
			return visibles;
		}

		/**
		 * Return list of RectSlots currently visible within frame bounds, 
		 * plus the additonal slots on either side equal to buffer amount.
		 * @param cardBuffer - amount of cards on each sides of visible cards to include in returned list.
		 * @return 
		 * 
		 */
		/*
		public function getActiveSlots( cardBuffer:int = 0 ):Vector.<RectSlot> 
		{
			var visibles:Vector.<RectSlot> = this.visibleSlots;
			
			if( cardBuffer > 0 )
			{
				var startIndex:int = visibles[0].index;
				var endIndex:int = visibles[visibles.length - 1].index
				var nextIndex:int;
				
				for (var j:int = 1; j <= cardBuffer; j++) 
				{
					nextIndex = startIndex - j;
					if( nextIndex > -1 )
					{
						visibles.unshift( _slots[nextIndex] )
					}
					nextIndex = endIndex + j;
					if( nextIndex < _slots.length )
					{
						visibles.push( _slots[nextIndex] );	// check if within length
					}
				}
			}
			return visibles;
		}
		*/
	}
}