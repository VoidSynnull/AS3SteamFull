package game.scenes.virusHunter.foreArm.components
{
	import ash.core.Component;
	
	public class Cut extends Component
	{				
		public var state:String = OPEN;
		public var health:Number = 0;
		public var maxHealth:Number = 4;
		
		public const OPEN:String = "open";
		public const SEALED:String = "sealed";
	}
}