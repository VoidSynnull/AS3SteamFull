package game.scenes.cavern1.shared.components
{
	import ash.core.Component;
	
	public class Magnetic extends Component
	{
		private var _isMovable:Boolean = false;
		
		public function Magnetic(isMovable:Boolean = true)
		{
			this.isMovable = isMovable;
		}
		
		public function get isMovable():Boolean { return _isMovable; }
		public function set isMovable(value:Boolean):void
		{
			if(_isMovable != value)
			{
				_isMovable = value;
			}
		}
	}
}