package game.scenes.carnival.autoRepair.components
{
	import ash.core.Component;
	
	/**
	 * HydraulicDirection. Can be -1,0,1
	 */
	public class HydraulicDirection extends Component
	{
		private var _direction:int;
		private var _min:int 
		private var _max:int
		private var _tweening:Boolean
		
		public function HydraulicDirection()
		{
			this._direction = 0;
			_tweening = false
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
		
		public function get tweening():Boolean
		{
			return _tweening;
		}
		
		public function set tweening(value:Boolean):void
		{
			_tweening = value;
		}
		
		
	}
}


