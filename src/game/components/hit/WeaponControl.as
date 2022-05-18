package game.components.hit
{
	import ash.core.Component;
	
	public class WeaponControl extends Component
	{
		public function WeaponControl()
		{
			
		}
		
		public var fire:Boolean;
		public var lockWhenInputInactive:Boolean = false;
		public var locked:Boolean = false;
	}
}