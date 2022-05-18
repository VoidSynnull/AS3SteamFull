package game.components.hit
{
	import ash.core.Component;
	
	public class WeaponControlInput extends Component
	{
		public function WeaponControlInput(fireKey:uint = 0)
		{
			this.fireKey = fireKey;
		}
		
		public var fireKey:uint;
	}
}