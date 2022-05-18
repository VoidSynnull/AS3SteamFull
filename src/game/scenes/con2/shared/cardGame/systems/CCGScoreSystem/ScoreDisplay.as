package game.scenes.con2.shared.cardGame.systems.CCGScoreSystem
{
	import ash.core.Component;
	
	import game.scenes.con2.shared.cardGame.CCGUser;
	
	public class ScoreDisplay extends Component
	{
		public var user:CCGUser;
		public var visualSpeed:Number;
		public var time:Number;
		public var score:int;
		public var original:uint;
		public var scoreDifference:int;
		public function ScoreDisplay(user:CCGUser, speed:Number = 1)
		{
			this.user = user;
			this.visualSpeed = speed;
			time = 0;
			score = 0;
			original = 0;
			scoreDifference;
		}
	}
}