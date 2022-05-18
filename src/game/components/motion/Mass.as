package game.components.motion
{
	import ash.core.Component;
	
	public class Mass extends Component
	{
		public function Mass(mass:Number = 100)
		{
			this.mass = mass;
		}
		
		public var mass:Number;
	}
}