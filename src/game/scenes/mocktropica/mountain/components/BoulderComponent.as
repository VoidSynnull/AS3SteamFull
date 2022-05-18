package game.scenes.mocktropica.mountain.components
{
	import ash.core.Component;
	
	public class BoulderComponent extends Component
	{
		public var firstHit:Boolean = false;
		public var startY:Number;
		public var hit:Boolean = false;
		public var lastY:Number = 0;
		public var rebound:Boolean = false;
	}
}