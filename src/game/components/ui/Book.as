package game.components.ui
{
	import ash.core.Component;
	
	import org.osflash.signals.Signal;
	
	public class Book extends Component
	{
		public const SECTION_HORIZONTAL:int = 0;
		public const SECTION_VERTICAL:int	= 1;
		
		/**
		 * Invalidate is managed by the Book System and should not be manually changed.
		 */
		public var invalidate:Boolean = false;
		
		/**
		 * If true, the Book will ease to the target page based on its distance.
		 * If false, the Book will immediately flip to the target page.
		 */
		public var ease:Boolean = true;
		
		/**
		 * If ease is true, the Book will ease to the target page based on its distance times this rate.
		 */
		public var rate:Number = 2;
		
		public var wrap:Boolean = false;
		
		private var _offsetX:Number;
		private var _offsetY:Number;
		
		private var _pageWidth:Number;
		private var _pageHeight:Number;
		
		private var _page:int;
		private var _numPages:int;
		
		private var _numSections:int = 1;
		public var section:int = SECTION_HORIZONTAL;
		
		public var minDelta:Number = 0.1;
		
		public var pageTurnFinished:Signal = new Signal();
		
		public function Book(page:int, numPages:int, pageWidth:Number, pageHeight:Number)
		{
			this._page 			= page;
			this._numPages 		= numPages;
			this._pageWidth		= pageWidth;
			this._pageHeight 	= pageHeight;
			
			this.recalculate();
		}
		
		public function get page():int { return this._page; }
		public function set page(page:int):void
		{
			if(this.wrap && numPages > 0)
			{
				while(page < 1)
				{
					page = this._numPages + page;
				}
				while(page > this._numPages)
				{
					page = page - this._numPages;
				}
			}
			else
			{
				if(page < 1)
				{
					page = 1;
				}
				else if(page > this._numPages)
				{
					page = this._numPages;
				}
			}
			
			if(this._page != page)
			{
				this._page = page;
				this.recalculate();
			}
		}
		
		public function get pageWidth():Number { return _pageWidth; }
		public function set pageWidth(pageWidth:Number):void
		{
			if(this._pageWidth != pageWidth)
			{
				this._pageWidth = pageWidth;
				this.recalculate();
			}
		}
		
		public function get pageHeight():Number { return _pageHeight; }
		public function set pageHeight(pageHeight:Number):void
		{
			if(this._pageHeight != pageHeight)
			{
				this._pageHeight = pageHeight;
				this.recalculate();
			}
		}
		
		public function get numPages():int { return _numPages; }
		public function set numPages(numPages:int):void
		{
			if(numPages < 1) numPages = 1;
			
			if(this._numPages != numPages)
			{
				this._numPages = numPages;
				
				if(this._page > this._numPages)
				{
					this._page = this._numPages;
				}
				
				this.recalculate();
			}
		}
		
		public function get numSections():int { return this._numSections; }
		public function set numSections(numSections:int):void
		{
			if(numSections < 1)
			{
				numSections = 1;
			}
			
			if(this._numSections != numSections)
			{
				this._numSections = numSections;
				this.recalculate();
			}
		}
		
		private function recalculate():void
		{
			var x:int = 0;
			var y:int = 0;
			
			switch(this.section)
			{
				case this.SECTION_HORIZONTAL:
					y = this._page - 1;
					
					while(y > this._numSections - 1)
					{
						y -= this._numSections;
						x++;
					}
					break;
				
				case this.SECTION_VERTICAL:
					x = this._page - 1;
					
					while(x > this._numSections - 1)
					{
						x -= this._numSections;
						y++;
					}
					break;
			}
			
			this._offsetX = -x * this._pageWidth;
			this._offsetY = -y * this._pageHeight;
			
			this.invalidate = true;
		}
		
		/**
		 * OffsetX is only altered internally. It's used to specify the target x offset to reach a new page.
		 */
		public function get offsetX():int { return _offsetX; }
		
		/**
		 * OffsetY is only altered internally. It's used to specify the target y offset to reach a new page.
		 */
		public function get offsetY():int { return _offsetY; }
	}
}