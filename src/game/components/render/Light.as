package game.components.render
{
	import ash.core.Component;
	
	public class Light extends Component
	{
		public function Light(radius:Number = 100, darkAlpha:Number = .9, lightAlpha:Number = 0, gradient:Boolean = true, color:uint = 0x000000, color2:uint = 0x000000)
		{
			this.radius = radius;
			this.darkAlpha = darkAlpha;
			this.gradient = gradient;
			this.color = color;
			this.color2 = color2;
			this.lightAlpha = lightAlpha;
		}
		
		public var radius:Number;
		public var darkAlpha:Number;
		public var gradient:Boolean;
		public var color:uint;
		public var color2:uint;
		public var lightAlpha:Number;
		public var matchOverlayDarkAlpha:Boolean = false;
	}
}