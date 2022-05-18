package game.scenes.cavern1.shared.components
{
	import ash.core.Component;
	import ash.core.Entity;
	
	public class Breakable extends Component
	{
		public var falling:Boolean = false;
		public var fallDelay:Number;
		public var explosiveness:Number;
		public var delay:Number = 0;
		public var platform:Entity;
		public function Breakable(platForm:Entity, fallDelay:Number = .25, explosiveness:Number = 0)
		{
			this.platform = platForm;
			this.fallDelay = fallDelay;
			this.explosiveness = explosiveness;
		}
	}
}