package game.scenes.mocktropica.server.component
{
	import ash.core.Component;
	
	public class SwitchValue extends Component
	{
		private var _val:int
		
		public function SwitchValue(i:int)
		{
			_val = i
		}
		
		public function get value():int
		{
			return _val;
		}
		
		public function set value(value:int):void
		{
			_val = value;
		}
		
	}
}