package game.scenes.timmy.chase.trashTruck
{
	import ash.core.Component;
	
	public class TrashTruck extends Component
	{		
		public static const WAIT:String = "wait";
		public static const MOVE:String = "move";
		public static const STOP:String = "stop";

		public var topLimit:Number = 0;
		public var bottomLimit:Number = 1000;
		
		public var nextTargetY:Number = 0;
 		public var targetDirection:Number = 1;//-1
		
		public var speed:Number = 100;
		
		public var moveDelay:Number = 0;
		public var timer:Number = 0;
		
		public var state:String = TrashTruck.WAIT;
		public var stateChanged:Boolean = false;

		public function TrashTruck(topLimit:Number = 0,  bottomLimit:Number = 1000, speed:Number = 100, moveDelay:Number = 1.0)
		{
			this.topLimit = topLimit;
			this.bottomLimit = bottomLimit;
			this.speed = speed;
			this.moveDelay = moveDelay;
		}
		
		public function setState(newState:String):void
		{
			if(this.state != newState){
				this.state = newState;
				this.stateChanged = true;
			}
		}
	}
}