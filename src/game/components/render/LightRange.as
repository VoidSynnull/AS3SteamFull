package game.components.render
{
	import ash.core.Component;
	
	public class LightRange extends Component
	{
		public function LightRange(min:Number = 0, max:Number = 1000, minRadius:Number = 100, maxDarkAlpha:Number = .8, maxLightAlpha:Number = 0, horizontalRange:Boolean = false)
		{
			this.min = min;
			this.max = max;
			this.minRadius = minRadius;
			this.maxDarkAlpha = maxDarkAlpha;
			this.maxLightAlpha = maxLightAlpha;
			this.horizontalRange = horizontalRange;
		}
		
		public function set min(min:Number):void
		{
			_min = min;
			
			this.range = _max - _min;
		}
		
		public function set max(max:Number):void
		{
			_max = max;
			
			this.range = _max - _min;
		}
		
		public function get min():Number { return(_min); }
		public function get max():Number { return(_max); }
		
		public var minRadius:Number;
		public var maxDarkAlpha:Number;
		public var maxLightAlpha:Number;
		public var range:Number;
		public var baseDarkAlpha:Number;
		public var baseLightAlpha:Number;
		public var baseRadius:Number;
		public var horizontalRange:Boolean = false;
		
		private var _min:Number;
		private var _max:Number;
	}
}