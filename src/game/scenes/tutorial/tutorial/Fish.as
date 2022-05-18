package game.scenes.tutorial.tutorial
{
	import ash.core.Component;
	
	public class Fish extends Component
	{
		public function Fish(periodIncrement:Number, periodOffset:Number, direction:Number)
		{
			this.periodIncrement = periodIncrement;
			this.periodOffset = periodOffset;
			this.direction = direction;
		}
		
		public var periodIncrement:Number;
		public var periodOffset:Number;
		public var direction:Number;
		public var period:Number = 0;
	}
}