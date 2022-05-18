package game.scenes.virusHunter.shared.components
{
	import ash.core.Component;
	
	public class JoesHealth extends Component
	{
		public var percent:Number = 1;
		public var currentHealth:Number = 1000;
		public var range:Number = 1000;
		public var timer:Number = 0;
		public var timerWait:Number = 200;
		public var damageTick:Boolean = false;
	}
}