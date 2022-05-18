package game.scenes.con2.shared.cardGame
{
	public class CCGScore
	{
		public const WINNING_SCORE:uint = 13;
		public var score:int;
		
		public function CCGScore()
		{
			score = 0;
		}
		
		public function hasWinningScore():Boolean
		{
			return score == WINNING_SCORE;
		}
		
		public function winningPoints(points:Number):Boolean
		{
			return (score + points == WINNING_SCORE);
		}
		
		public function validPoints(points:Number):Boolean
		{
			return (score + points <= WINNING_SCORE && score + points >= 0);
		}
		
		public function addPoints(points:int):void
		{
			score += points;
		}
		
		public function removePoints(points:int):void
		{
			score -= points;
		}
	}
}