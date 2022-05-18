package game.data
{
	import flash.display.BitmapData;

	public class BitmapFrameData
	{
		public var data:BitmapData;
		public var x:Number;
		public var y:Number;

		public function BitmapFrameData(data:BitmapData, x:Number, y:Number)
		{
			this.data = data;
			this.x = x;
			this.y = y;
		}
		
		public function destroy():void
		{
			data.dispose();
			data = null;
		}
	}
}