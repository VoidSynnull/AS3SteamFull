package game.components.motion
{
	import ash.core.Component;
	
	import engine.components.Motion;
	
	public class Draft extends Component
	{
		public var motion:Motion;
		public var gravityDampening:Number;
		public function Draft(motion:Motion, dampening:Number = 0)
		{
			this.motion = motion;
			gravityDampening = dampening;
		}
	}
}