package game.components.specialAbility.character
{
	import ash.core.Component;
	
	public class MotionBlur extends Component
	{
		public var lifeTime:Number;
		public var color:uint;
		public var colorize:Boolean;
		public var rate:Number;
		public var time:Number;
		public var quality:Number;
		public var startAlpha:Number = 1;
		
		public function MotionBlur(lifeTime:Number = 1, blursPerSecond:Number = 10, quality:Number = 1, color:Number = NaN, startAlpha:Number = NaN)
		{
			this.lifeTime = lifeTime;
			this.color = color;
			this.quality = quality;
			if(!isNaN(startAlpha)) this.startAlpha = startAlpha;
			
			colorize = !isNaN(color);
			rate = 1/blursPerSecond;
			time = 0;
		}
	}
}
