package game.scenes.reality2.shared
{
	import ash.core.Component;

	public class Contestant extends Component
	{
		public var id:String;//name of contestant
		public var index:int;//index of all possible contestants
		public var score:int;//score talley
		public var difficulty:Number;// how smart they are easy, medium, hard, (ai) or player
		public var place:int;
		
		public function Contestant(index:int)
		{
			this.index = index;
			score = 0;
			difficulty = NORMAL;
		}
		
		public function duplicate():Contestant
		{
			var contestant:Contestant = new Contestant(this.index);
			contestant.difficulty = this.difficulty;
			contestant.id = this.id;
			contestant.score = this.score;
			return contestant;
		}
		
		// accuracy of tasks
		public static const EASY:Number = .33;
		public static const NORMAL:Number = .66;
		public static const HARD:Number = .75;
		public static const PLAYER:Number = 1;
	}
}