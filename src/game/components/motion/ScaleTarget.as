package game.components.motion
{
	import ash.core.Component;
	
	public class ScaleTarget extends Component
	{
		public function ScaleTarget(target:Number = NaN)
		{
			this.target = target;	
		}
		
		public var target:Number;
		public var scaleStep:Number = .5;
	}
}