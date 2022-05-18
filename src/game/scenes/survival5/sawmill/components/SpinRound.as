package game.scenes.survival5.sawmill.components
{
	import ash.core.Component;
	import ash.core.Entity;
	
	public class SpinRound extends Component
	{
		public function SpinRound(target:Entity, radius:Number, offset:Number = 0)
		{
			this.target = target;
			this.radius = radius;
			this.offset = offset;
		}
		
		public var target:Entity;
		public var radius:Number;
		public var offset:Number;
	}
}