package game.scenes.virusHunter.day2Heart.components 
{
	import ash.core.Entity;
	
	import ash.core.Component;
	
	public class WormMass extends Component
	{
		public var boss:Entity;
		public var wormBoss:WormBoss;
		public var state:String;
		
		public static const IDLE_STATE:String		= "idle_state";
		public static const EXPAND_STATE:String		= "expand_state";
		public static const CONTRACT_STATE:String	= "contract_state";
		
		public function WormMass(boss:Entity, wormBoss:WormBoss)
		{
			this.boss = boss;
			this.wormBoss = wormBoss;
			this.state = WormMass.IDLE_STATE;
		}
	}
}