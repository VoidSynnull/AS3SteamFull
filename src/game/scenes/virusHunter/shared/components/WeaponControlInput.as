package game.scenes.virusHunter.shared.components
{
	import ash.core.Component;
	
	public class WeaponControlInput extends Component
	{
		public function WeaponControlInput(fireKey:uint = 0)
		{
			this.fireKey = fireKey;
		}
		
		public var fireKey:uint;
		public var triggerWeaponSelection:Boolean;
	}
}