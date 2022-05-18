package game.scenes.deepDive1.shipUnderside
{
	import ash.core.Component;
	
	public class BackgroundFishDir extends Component
	{
		private var _direction:int;
		private var _speed:Number;
		private var _min:int 
		private var _max:int
		
		public function BackgroundFishDir()
		{
			this._direction = 0;
		}
		
		public function get max():int
		{
			return _max;
		}
		
		public function set max(value:int):void
		{
			_max = value;
		}
		
		public function get min():int
		{
			return _min;
		}
		
		public function set min(value:int):void
		{
			_min = value;
		}
		
		public function get direction():int { return this._direction; }
		
		public function set direction(direction:int):void { this._direction = direction; }
		
		public function get speed():Number
		{
			return _speed;
		}
		
		public function set speed(value:Number):void
		{
			_speed = value;
		}
		
		
	}
}

