package game.scenes.virusHunter.shipDemo.components
{
	import ash.core.Component;
	
	public class PointValue extends Component
	{
		public function PointValue(value:Number)
		{
			this.value = value;
		}
		
		public var value:Number;
		public var _redeem:Boolean = false;
	}
}