package game.components.motion
{
	import ash.core.Component;
	
	public class Magnet extends Component
	{
		public function Magnet(force:Number, fieldRadius:Number, polarity:uint = 0)
		{
			this.force = force;
			this.polarity = polarity;
			this.field = fieldRadius;
		}
		
		public var active:Boolean = true;
		public var force:Number;
		public var polarity:uint;
		public var field:Number
		
		public static var NORTH:uint = 0;
		public static var SOUTH:uint = 1;
	}
}