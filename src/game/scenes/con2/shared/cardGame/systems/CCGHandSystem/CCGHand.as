package game.scenes.con2.shared.cardGame.systems.CCGHandSystem
{
	import ash.core.Component;
	import ash.core.Entity;
	
	import game.scenes.con2.shared.cardGame.CCGUser;
	
	public class CCGHand extends Component
	{
		public var user:CCGUser;
		public var selectedCard:Entity;
		public var takeCurrentSelection:Boolean;
		public function CCGHand(user:CCGUser)
		{
			this.user = user;
			takeCurrentSelection = false;
		}
	}
}