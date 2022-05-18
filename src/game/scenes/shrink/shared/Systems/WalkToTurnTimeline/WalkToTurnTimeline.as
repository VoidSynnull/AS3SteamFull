package game.scenes.shrink.shared.Systems.WalkToTurnTimeline
{
	import ash.core.Component;
	
	import game.scenes.shrink.shared.Systems.WalkToTurnDialSystem.WalkToTurnDial;
	
	public class WalkToTurnTimeline extends Component
	{
		public var dial:WalkToTurnDial;
		public var lastValue:Number = 0;
		public var right:String;
		public var left:String;
		public var turningRight:Boolean = true;
		
		public var stopTurnTime:Number = .1;
		
		public var time:Number = 0;
		
		public function WalkToTurnTimeline(dial:WalkToTurnDial, right:String, left:String)
		{
			this.dial = dial;
			this.right = right;
			this.left = left;
		}
	}
}