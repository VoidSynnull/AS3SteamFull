package game.components.entity.character
{
	import ash.core.Component;
	
	public class CharacterWander extends Component
	{
		public function CharacterWander(rangeX:Number = 0, rangeY:Number = 0)
		{
			this.rangeX = rangeX;
			this.rangeY = rangeY;
		}
				
		public var rangeX:Number;
		public var rangeY:Number;
		public var state:String;
		public var remainingWaitTime:Number = 0;
		public var minTimeToWait:Number = .2;
		public var maxTimeToWait:Number = 5;
		public var acceleration:Number = 400;
		public var pause:Boolean = false;
		public var disabled:Boolean = false;
		
		public var _targetX:Number;
		public var _targetY:Number;
		public var _initX:Number;
		public var _initY:Number;
		
		public const START_MOVE:String = "startMove";
		public const MOVE:String = "move";
		public const WAIT:String = "wait";
		public const PAUSED:String = "paused";
	}
}