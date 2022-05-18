package game.scenes.carnival.shared.popups.duckGame
{
	import ash.core.Component;
	
	public class ColorNum extends Component
	{
		private var _num:int
		
		public function ColorNum()
		{
		}
		
		public function get num():int
		{
			return _num;
		}
		
		public function set num(value:int):void
		{
			_num = value;
		}
		
	}
}