package game.scenes.survival1.shared.components
{
	import ash.core.Component;
	
	public class WindBlock extends Component
	{
		public var right:Boolean;
		public var left:Boolean;
		public function WindBlock(right:Boolean = false, left:Boolean = false)
		{
			this.right = right;
			this.left = left;
		}
	}
}