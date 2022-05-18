package game.scenes.virusHunter.mouth.components
{
	import ash.core.Entity;
	
	import ash.core.Component;
	
	public class Bubble extends Component
	{
		public var float:Entity;
		public var blink:Entity;
		public var platform:Entity;
		
		public var init:Boolean = false;
		public var cooldown:Boolean = false;
		public var popping:Boolean = false;
		public var recycled:Boolean = false;
		public var firstLand:Boolean = true;
		public var playSound:Boolean = true;
	}
}