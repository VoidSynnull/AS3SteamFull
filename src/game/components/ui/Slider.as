package game.components.ui
{
	import ash.core.Component;

	public class Slider extends Component
	{
		public var inverse:Boolean;
		public function Slider(inverse:Boolean = false)
		{
			this.inverse = inverse;
		}
	}
}
