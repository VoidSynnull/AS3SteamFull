package game.scenes.virusHunter.foreArm.components
{
	import ash.core.Component;
	
	
	public class ForeArmState extends Component
	{
		public const IDLE:String 	= "idle";
		public const BATTLE:String	= "battle";
		public const BATTLE_WON:String 	= "battleWon";
		public const SPAWNS_KILLED:String = "spawnsKilled";
		
		public var state:String;
		public var wait:Number;
	
		public const TOTAL_SPAWNS:int = 2;

		public function ForeArmState( state:String = IDLE )
		{
			this.state = state;
		}
		
	}
}

