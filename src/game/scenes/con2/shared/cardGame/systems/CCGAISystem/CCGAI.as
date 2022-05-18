package game.scenes.con2.shared.cardGame.systems.CCGAISystem
{
	import ash.core.Component;
	
	import game.scenes.con2.shared.cardGame.CardGame;

	public class CCGAI extends Component
	{
		public var type:String;
		public var game:CardGame;		
		public var decisionTimes:Number;
		public var time:Number;
		public var placement:String;
		
		public function CCGAI(game:CardGame, decisionTimes:Number = 1, aiType:String = "random")
		{
			this.game = game;
			this.decisionTimes = decisionTimes;
			type = aiType;
			time = 0;
			placement = "bounty";
		}
		
		public static const RANDOM:String = "random";
		public static const SMART:String = "smart";
		public static const TO_13:String = "to_13";
	}
}