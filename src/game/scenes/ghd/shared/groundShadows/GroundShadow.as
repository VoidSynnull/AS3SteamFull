package game.scenes.ghd.shared.groundShadows
{
	import ash.core.Component;
	
	public class GroundShadow extends Component
	{
		public var scaleCurrent:Number = 1.0;
		public var scaleMax:Number = 1.5;
		public var scaleMin:Number = 0.3;
		
		public var scaleMultiplyer:Number = 10.0;
		
		public var on:Boolean = true;

		public function GroundShadow()
		{
			
		}
	}
}