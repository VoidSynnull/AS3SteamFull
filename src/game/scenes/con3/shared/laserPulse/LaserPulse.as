package game.scenes.con3.shared.laserPulse
{
	import ash.core.Component;
	
	import game.scenes.con3.shared.rayCollision.RayCollision;
	
	public class LaserPulse extends Component
	{
		internal var _rayCollision:RayCollision;
		internal var _on:Boolean = true;
		public var time:Number = 0;
		public var timeOn:Number = 2;
		public var timeOff:Number = 4;
		
		public function LaserPulse()
		{
			super();
		}
	}
}