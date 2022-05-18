package game.scenes.con3.shared.rayCollision
{
	import flash.display.Bitmap;
	
	import ash.core.Component;
	
	public class RayCollision extends Component
	{
		internal var _bitmap:Bitmap = new Bitmap();
		internal var _length:Number;
		internal var _rayLength:Number;
		
		public function RayCollision()
		{
			
		}
		
		public function get length():Number { return this._length; }
		public function set length(length:Number):void
		{
			if(isFinite(length) && length < this._length)
			{
				this._length = length;
			}
		}
		
		public function get shape():Bitmap { return this._bitmap; }
	}
}