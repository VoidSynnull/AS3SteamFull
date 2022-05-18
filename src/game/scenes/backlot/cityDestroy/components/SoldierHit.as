package game.scenes.backlot.cityDestroy.components
{
	import ash.core.Component;
	
	public class SoldierHit extends Component
	{
		public var recoveryTime:Number;
		public var time:Number;
		public function SoldierHit(recoveryTime:Number = .5)
		{
			this.recoveryTime = recoveryTime;
			time = 0;
		}
	}
}