package game.components.ui
{
	import ash.core.Component;
	
	public class Ratio extends Component
	{
		private var _decimal:Number = 0;
		private var _min:Number 	= 0;
		private var _max:Number 	= 1;
		
		public function Ratio(decimal:Number = 0, min:Number = 0, max:Number = 1)
		{
			this.set(decimal, min, max);
		}
		
		public function set(decimal:Number = 0, min:Number = 0, max:Number = 1):void
		{
			var recalculate:Boolean = false;
			
			if(this._min != min)
			{
				this._min = min;
				recalculate = true;
			}
			
			if(this._max != max)
			{
				this._max = max;
				recalculate = true;
			}
			
			if(recalculate)
			{
				this.checkMinMax();
			}
			
			this.decimal = decimal;
		}
		
		/**
		 * The minimum decimal value of the Ratio.
		 */
		public function get min():Number
		{
			return this._min;
		}
		
		public function set min(min:Number):void
		{
			if(this._min != min)
			{
				this._min = min;
				this.checkMinMax();
				this.decimal = this._decimal;
			}
		}
		
		/**
		 * The maximum decimal value of the Ratio.
		 */
		public function get max():Number
		{
			return this._max;
		}
		
		public function set max(max:Number):void
		{
			if(this._max != max)
			{
				this._max = max;
				this.checkMinMax();
				this.decimal = this._decimal;
			}
		}
		
		private function checkMinMax():void
		{
			if(this._min > this._max)
			{
				const max:Number 	= this._min;
				this._min 			= this._max;
				this._max 			= max;
			}
		}
		
		/**
		 * The percent form of the Ratio.
		 * 
		 * <p>If <code>decimal = 0.25</code>, then <code>percent = 25</code>.</p>
		 */
		public function get decimal():Number
		{
			return this._decimal;
		}
		
		public function set decimal(decimal:Number):void
		{
			if(decimal < this._min)
			{
				decimal = this._min;
			}
			else if(decimal > this._max)
			{
				decimal = this._max;
			}
			
			if(isFinite(decimal))
			{	
				this._decimal = decimal;
			}
		}
		
		public function setFrom(number:Number, min:Number, max:Number):void
		{
			this.decimal = (number - min) / (max - min);
		}
		
		/**
		 * The percent form of the Ratio.
		 * 
		 * <p>If <code>decimal = 0.25</code>, then <code>percent = 25</code>.</p>
		 */
		public function get percent():Number
		{
			return this._decimal * 100;
		}
		
		public function set percent(percent:Number):void
		{
			this.decimal = percent / 100;
		}
	}
}