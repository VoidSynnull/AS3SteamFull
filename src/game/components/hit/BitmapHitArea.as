package game.components.hit
{
	import flash.display.BitmapData;
	
	import ash.core.Component;
	
	public class BitmapHitArea extends Component
	{
		public function BitmapHitArea(hitArea:BitmapData)
		{
			_bitmapData = hitArea;
		}
		
		override public function destroy():void
		{
			if(_bitmapData)
			{
				_bitmapData.dispose();
				_bitmapData = null;
			}
			
			super.destroy();
		}
		
		public function get bitmapData():BitmapData { return(_bitmapData); }
		public function set bitmapData(bitmapData:BitmapData):void { _bitmapData = bitmapData; }
		private var _bitmapData:BitmapData;
		
		// for radial tests
		public var hitTestRadius:Number = 10;
		public var hitTestRadialSteps:Number = 48;
	}
}