package game.components.ui
{
	import flash.display.DisplayObject;
	import flash.geom.Rectangle;
	
	import ash.core.Component;
	
	public class ScrollBox extends Component
	{
		public function ScrollBox(container:DisplayObject, area:Rectangle, buffer:int = 10, rate:int = 10, isHorizontal:Boolean = true, offset:Number = 0)
		{
			this.container 		= container;
			this.area 			= area;
			this.buffer 		= buffer;
			this.rate 			= rate;
			this.isHorizontal 	= isHorizontal;
			this.offset = offset;
			
			createScrollAreas();
		}
		
		public function createScrollAreas( area:Rectangle = null, buffer:Number = NaN ):void
		{
			if( area != null ) { this.area = area; }
			if( !isNaN(buffer) ) { this.buffer = buffer; }
				
			if( isHorizontal )
			{
				min = new Rectangle( this.area.x - offset, this.area.y, this.buffer, this.area.height );
				max = new Rectangle( this.area.width - this.buffer + offset, this.area.y, this.buffer, this.area.height );
			}
			else
			{
				min = new Rectangle( this.area.x, this.area.y - offset, this.area.width, this.buffer );
				max = new Rectangle( this.area.x, this.area.height - this.buffer + offset, this.area.width, this.buffer );
			}
		}

		public var container:DisplayObject;
		public var area:Rectangle;
		public var min:Rectangle;
		public var max:Rectangle;
		public var buffer:Number;
		public var offset:Number;
		public var reverse:Boolean = false;
		public var isHorizontal:Boolean = true;
		public var rate:int = 10;
		public var disable:Boolean = false;
		
		//public var invalidate:Boolean = false;;
		private var _velocity:Number=0;
		public function get velocity():Number { return _velocity; }
		public function set velocity( value:Number ):void 
		{
			_velocity = value;
			//invalidate = true;
		}
	}
}