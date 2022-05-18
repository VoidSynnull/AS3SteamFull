package game.components.motion
{
	import ash.core.Component;
	
	public class DirectionalMover extends Component
	{
		public var veloctiy:Number;
		public var acceleration:Number;
		public function DirectionalMover(velocity:Number = 0, acceleration:Number = 0)
		{
			this.veloctiy = velocity;
			this.acceleration = acceleration;
		}
	}
}