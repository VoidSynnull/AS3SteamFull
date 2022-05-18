package game.scenes.gameJam.zombieDefense.components
{
	import ash.core.Component;
	
	public class DefenseTrap extends Component
	{
		public function DefenseTrap()
		{
			super();
		}
		
		public var effectTimer:Number = 0;
		public var effectDuration:Number = 1;
		public var rearmTimer:Number = 0;
		public var rearmTime:Number = 1;
		public var armed:Boolean = true;
		public var damage:int = 1;
		public var effect:String = NONE;
		
		public static const NONE:String = "none";
		public static const STUN:String = "stun";
		public static const SLOW:String = "slow";
		public static const KNOCKBACK:String = "knockBack";

	}
}