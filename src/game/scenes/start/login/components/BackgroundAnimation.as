package game.scenes.start.login.components
{
	import ash.core.Component;
	
	import game.scenes.start.login.data.BackgroundAnimationData;
	
	public class BackgroundAnimation extends Component
	{
		public var data:BackgroundAnimationData;
		public function BackgroundAnimation(data:BackgroundAnimationData)
		{
			this.data = data;
		}
	}
}