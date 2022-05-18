package game.scenes.prison.messHall.foodFight
{
	import ash.core.Component;
	
	import game.data.TimedEvent;
	
	public class FlyingFood extends Component
	{
		public var flying:Boolean = false;
		public var flySpeed:Number = -800;
		public var gravity:Number = 160;
		public var lifetime:Number = 2.0;
		public var killTimer:TimedEvent;
		
		public function FlyingFood()
		{
			super();
		}
	}
}