package game.components.specialAbility.character
{
	import ash.core.Component;
	import engine.components.Display;

	public class FlashlightEffect extends Component
	{
		public var lightRadius:uint;
		public var darkAlpha:Number;
		public var display:Display;
		
		public function FlashlightEffect(display:Display, lightRadius = 100, darkAlpha = 0.8)
		{
			this.display = display;
			this.lightRadius = lightRadius;
			this.darkAlpha = darkAlpha;
		}
	}
}