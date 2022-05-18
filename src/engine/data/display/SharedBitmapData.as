package engine.data.display
{
	import flash.display.BitmapData;
	
	public class SharedBitmapData extends BitmapData
	{
		internal var _bitmapsAddedTo:int = 0;
		
		public function SharedBitmapData(width:int, height:int, transparent:Boolean = true, fillColor:uint = 4.294967295E9)
		{
			super(width, height, transparent, fillColor);
		}
		
		override public function dispose():void
		{
			/*
			This was an attempt to reference count and only dispose of BitmapData when
			all Bitmaps sharing it weren't using it anymore. But there's no solid way of
			determining when Entities and their Display Components are removed and destroyed
			in a sequential order. Entities don't use Parent and Children Components appropriately
			in all instances. Groups make things a mess. - Drew
			/*
			/*if(this._bitmapsAddedTo == 0)
			{
				super.dispose();
			}*/
			
			super.dispose();
		}
		
		public function get bitmapsAddedTo():int { return this._bitmapsAddedTo; }
	}
}