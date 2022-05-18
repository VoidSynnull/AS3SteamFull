package game.scenes.con2.shared.turnBased
{
	import ash.core.Component;
	
	public class TurnBasePlayer extends Component
	{
		public function TurnBasePlayer(userControlled:Boolean, index:int = 0)
		{
			isUserControlled = userControlled;
			isActive = false;
		}
		
		public var index:Number;
		public var isUserControlled:Boolean;
		public var isActive:Boolean;
	}
}