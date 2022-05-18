package game.scenes.prison.yard.components
{
	import ash.core.Component;
	
	public class Seagull extends Component
	{
		public function Seagull(flySpeed:Number = 600, landDist:Number = 200, nestScale:Number = 1)
		{
			this.flySpeed = flySpeed;
			this.landDist = landDist;
			this.nestDirection = nestScale;
		}
		
		public var flySpeed:Number;
		public var landDist:Number;
		public var nestDirection:Number;
	}
}