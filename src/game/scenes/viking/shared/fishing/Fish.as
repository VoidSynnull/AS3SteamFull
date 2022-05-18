package game.scenes.viking.shared.fishing
{
	import ash.core.Component;
	
	public class Fish extends Component
	{
		public static const SWIM:String = "swim";
		public static const IDLE:String = "idle";
		public static const FLOP:String = "flop";
		
		public var state:String = IDLE;
		public var stateChanged:Boolean = false;
		public var direction:String = "right";// "left"
		public var speed:Number = 100;
		public var range:Number = 250;
		public var idleTime:Number = 4.0;
		public var timeElapsed:Number = 0;
		
		public function setState(newState:String):void
		{
			state = newState;
			stateChanged = true;
		}
	}
}