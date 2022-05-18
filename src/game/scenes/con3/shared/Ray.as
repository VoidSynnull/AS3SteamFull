package game.scenes.con3.shared
{
	import ash.core.Component;
	
	public class Ray extends Component
	{
		internal var _length:Number = 2000;
		
		public function Ray(length:Number = 2000)
		{
			this.length = length;
		}
		
		public function get length():Number { return this._length; }
		public function set length(length:Number):void
		{
			if(isFinite(length) && length >= 0)
			{
				this._length = length;
			}
		}
	}
}