package game.scenes.carnival.shared.popups.duckGame
{
	import ash.core.Component;
	
	/**
	 * DuckMoverComponent.
	 */
	public class DuckMover extends Component
	{
		private var _dx:Number;
		private var _dy:Number;
		
		public function DuckMover()
		{
		}
		
		public function get dx():Number
		{
			return _dx;
		}
		
		public function set dx(value:Number):void
		{
			_dx = value;
		}
		
		public function get dy():Number
		{
			return _dy;
		}
		
		public function set dy(value:Number):void
		{
			_dy = value;
		}
		
		
	}
}



