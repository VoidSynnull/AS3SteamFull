package game.components.motion
{
	import ash.core.Component;
	
	public class FollowInput extends Component
	{
		public function FollowInput(rate:Number = 1)
		{
			this.rate = rate;
		}
		
		public var rate:Number;
	}
}