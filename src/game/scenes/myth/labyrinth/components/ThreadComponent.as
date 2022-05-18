package game.scenes.myth.labyrinth.components
{
	import flash.display.Sprite;
	
	import ash.core.Component;
	
	public class ThreadComponent extends Component
	{
		public var lastX:Number;
		public var lastY:Number;
		public var trail:Sprite;
		public var supported:Boolean = true;
	}
}