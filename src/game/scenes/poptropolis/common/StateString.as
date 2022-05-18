package game.scenes.poptropolis.common
{
	import ash.core.Component;
	
	public class StateString extends Component
	{
		private var _state:String = "none"
		
		public function StateString(__s:String)
		{
			_state = __s
		}
		
		public function get state():String
		{
			return _state;
		}
		
		public function set state(value:String):void
		{
			_state = value;
		}
		
	}
}