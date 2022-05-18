package game.components.render
{
	import ash.core.Component;
	
	public class LightOverlay extends Component
	{
		public function LightOverlay(darkAlpha:Number = .9, color:uint = 0x000000)
		{
			this.darkAlpha = darkAlpha;
			this.color = color;
		}
		
		public var darkAlpha:Number;
		public var color:uint;
	}
}