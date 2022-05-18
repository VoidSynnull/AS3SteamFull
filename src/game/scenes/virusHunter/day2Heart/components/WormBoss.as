package game.scenes.virusHunter.day2Heart.components 
{
	import ash.core.Component;
	
	public class WormBoss extends Component
	{
		public static const IDLE_STATE:String	= "idle_state";
		public static const SETUP_STATE:String 	= "setup_state";
		public static const VIEW_STATE:String 	= "view_state";
		public static const INTRO_STATE:String	= "intro_state";
		public static const MOVE_STATE:String	= "move_state";
		public static const ANGRY_STATE:String	= "angry_state";
		public static const DEATH_STATE:String	= "death_state";
		
		public var state:String;
		
		public var elapsedTime:Number;
		
		public var numMasses:uint;
		public var numTentacles:uint;
		
		public function WormBoss()
		{
			this.state = WormBoss.IDLE_STATE;
			
			this.elapsedTime = 0;
			
			this.numMasses = 4;
			this.numTentacles = 8;
		}
	}
}