package game.scenes.con2.shared.cardGame
{
	public class CCGEffects
	{
		public static const NONE:String = "none";//no speical effect
		public static const SKIP:String = "skip";//skips opponents next turn
		public static const BOTH:String = "both";//allows player to play a card in both slots
		public static const STEAL:String = "steal";//steals one gem from opponent and adds it as their own in addition to normal turn
		public static const DRAW:String = "draw";//draws an extra card
		public static const BLOCK:String = "block";//blocks opponent's cards with lesser or equal value (effects included)
		//potential new effects?
		/* as cool as the ability is to chage a card's value it is almost impossible to update so visually
		public static const IMITATE:String = "imitate";//value becomes equal to highest valued opponent's card
		public static const ENCOURAGE:String = "encourage";//increases all user's cards values by 1
		public static const DISCOURAGE:String = "discourage";//decreases all opponent's cards values by 1
		*/
		public static const ENRAGE:String = "enrage";//if opponent attacks, this card activates twice
		public static const GREED:String = "greed";//if opponent uses card in a bounty slot, this card activates twice
		//this card's value would have to be 0, because the ramifications for this ability could be brutal
		public static const DECEIVE:String = "deceive";//reverses the effects of opponent's cards
		public static const SACRIFICE:String = "sacrifice";//card requires a sacrafice to perform its action (reserved for overly strong cards)
	}
}