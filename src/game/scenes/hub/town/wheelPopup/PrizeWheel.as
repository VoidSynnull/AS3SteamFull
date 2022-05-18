package game.scenes.hub.town.wheelPopup
{
	import ash.core.Component;
	
	public class PrizeWheel extends Component
	{
		public var data:PrizeWheelData;
		public function PrizeWheel(data:PrizeWheelData = null)
		{
			this.data = data;
		}
		
		public function get randomPrizeNumber():int
		{
			var min:Number = 0;
			var accumulatedWeight:Number = 0;
			
			var val:Number = Math.random() * 100;
			
			var prize:PrizeData;
			
			for(var i:int = 0; i < data.prizes.length; ++i)
			{
				prize = data.prizes[i];
				accumulatedWeight += prize.weight;
				if(val <= accumulatedWeight && val > min)
					return i;
			}
			
			return -1;
		}
	}
}