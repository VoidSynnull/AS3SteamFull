package game.scenes.cavern1.shared.components
{
	import ash.core.Component;
	
	public class Magnet extends Component
	{
		private var _strength:Number = 400;
		
		public function Magnet(strength:Number = 400)
		{
			this.strength = strength;
		}
		
		public function get strength():Number { return _strength; }
		public function set strength(value:Number):void
		{
			if(_strength != value)
			{
				_strength = value;
			}
		}
	}
}