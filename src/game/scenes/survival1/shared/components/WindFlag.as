package game.scenes.survival1.shared.components
{
	import ash.core.Component;

	public class WindFlag extends Component
	{
		public var wind:SurvivalWind;
		public var windBlock:WindBlock;
		public var blocked:Boolean;
		public var windToFlagScale:Number;
		public function WindFlag(wind:SurvivalWind, windBlock:WindBlock, scale:Number = .01)
		{
			this.wind = wind;
			this.windBlock = windBlock;
			this.windToFlagScale = scale;
			blocked = false;
		}
	}
}