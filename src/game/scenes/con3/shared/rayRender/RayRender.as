package game.scenes.con3.shared.rayRender
{
	import flash.display.Bitmap;
	
	import ash.core.Component;
	
	public class RayRender extends Component
	{
		internal var _redraw:Boolean = true;
		internal var _resize:Boolean = true;
		
		internal var _bitmap:Bitmap = new Bitmap();
		internal var _color:uint = 0xFF0000;
		internal var _thickness:Number = 5;
		internal var _length:Number = 1000;
		
		internal var _invalidateLength:Number = 1000;
		internal var _lengthDifference:Number = 10;
		
		public function RayRender(length:Number = 1000, color:uint = 0xFF0000, thickness:Number = 5)
		{
			this.length = length;
			this.color = color;
			this.thickness = thickness;
		}
		
		public function get length():Number { return this._length; }
		public function set length(length:Number):void
		{
			if(isFinite(length) && length >= 0)
			{
				if(this._length != length)
				{
					this._length = length;
					
					if(Math.abs(this._length - this._invalidateLength) > this._lengthDifference)
					{
						this._invalidateLength = length;
						this._resize = true;
					}
				}
			}
		}
		
		public function get color():uint { return this._color; }
		public function set color(color:uint):void
		{
			if(this._color != color)
			{
				this._color = color;
				this._redraw = true;
			}
		}
		
		public function get thickness():Number { return this._thickness; }
		public function set thickness(thickness:Number):void
		{
			if(isFinite(thickness) && thickness >= 0)
			{
				if(this._thickness != thickness)
				{
					this._thickness = thickness;
					this._redraw = true;
				}
			}
		}
	}
}