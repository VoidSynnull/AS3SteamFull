package game.scenes.virusHunter.hand.components
{
	import ash.core.Component;
	import engine.components.Motion;
	import engine.components.Spatial;
	
//	import game.data.character.LookData;
	
	public class HandState extends Component
	{
		public const IDLE:String = "idle";
		public const BATTLE:String 	= "battle";
		public const ESCAPE:String 	= "escape";
		public const ROBBED:String 	= "robbed";
		public const TARGET_PLAYER:String	= "target_player";
		
		public const STEAL_ANTIGRAV:String = "steal_antiGrav";
		public const STEAL_SHIELD:String = "steal_shield";
		public const STEAL_SCALPEL:String = "steal_scalpel";
		public const STEAL_GOO:String = "steal_goo";
		public const STEAL_SHOCK:String = "steal_shock";
		
		public const TOTAL_BACTERIA:int = 15;
		
		public var state:String;
		public var motion:Motion;
		public var spatial:Spatial;
		public var gotLook:Boolean = false;
		
		public function HandState( state:String = IDLE )
		{
			this.state = state;
		}
		
	}
}

