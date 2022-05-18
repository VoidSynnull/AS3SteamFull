package game.scenes.virusHunter.shared.components
{
	import ash.core.Component;
	
	public class Ship extends Component
	{
		public var damageVelocity:Number = 400;
		public var state:String;
		public var locked:Boolean = false;
		public var unlock:Boolean = false;
		public var engineSoundFadeOut:Boolean = false;
		public const ALIVE:String = "alive";
		public const DEAD:String = "dead";
	}
}