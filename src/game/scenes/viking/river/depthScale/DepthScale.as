package game.scenes.viking.river.depthScale
{
	import ash.core.Component;
	
	public class DepthScale extends Component
	{
		internal var _minY:Number = 0;
		internal var _maxY:Number = 0;
		
		internal var _minScale:Number = 0.5;
		internal var _maxScale:Number = 1.5;
		
		internal var _limit:Boolean = true;
		
		public function DepthScale(minY:Number = 0, maxY:Number = 0, minScale:Number = 0, maxScale:Number = 1, limit:Boolean = true)
		{
			this.minY = minY;
			this.maxY = maxY;
			this.minScale = minScale;
			this.maxScale = maxScale;
			this.limit = limit;
		}
		
		public function get limit():Boolean
		{
			return this._limit;
		}
		
		public function set limit(limit:Boolean):void
		{
			this._limit = limit;
		}
		
		public function get minY():Number
		{
			return this._minY;
		}
		
		public function set minY(minY:Number):void
		{
			this._minY = minY;
		}
		
		public function get maxY():Number
		{
			return this._maxY;
		}
		
		public function set maxY(maxY:Number):void
		{
			this._maxY = maxY;
		}
		
		public function get minScale():Number
		{
			return this._minScale;
		}
		
		public function set minScale(minScale:Number):void
		{
			this._minScale = minScale;
		}
		
		public function get maxScale():Number
		{
			return this._maxScale;
		}
		
		public function set maxScale(maxScale:Number):void
		{
			this._maxScale = maxScale;
		}
	}
}