package game.scenes.survival2.shared.flippingRocks
{
	import ash.core.Component;
	
	import game.components.timeline.Timeline;
	
	import org.osflash.signals.Signal;
	
	public class FlippableRock extends Component
	{
		public var currentPosition:int = 0;
		public var positions:int;
		public const POSITION:String = "position";
		public var timeline:Timeline;
		public var flipped:Signal;
		public var lockPosition:int;
		public var locked:Boolean = false;
		public var objectName:String;
		public var flippingForward:Boolean;
		public var top:Boolean;
		
		public function farLeft():Boolean
		{
			return currentPosition <= 1;
		}
		
		public function farRight():Boolean
		{
			return currentPosition >= positions;
		}
		
		public function canFlip():Boolean
		{
			if(locked || farLeft() && !flippingForward || farRight() && flippingForward)
				return false;
			return true;
		}
		
		public function FlippableRock(timeline:Timeline, positions:int, startPosition:int = 1, lockPosition:int = 0, top:Boolean = false)
		{
			this.timeline = timeline;
			currentPosition = startPosition;
			this.positions = positions;
			timeline.gotoAndStop(POSITION+currentPosition);
			flipped = new Signal();
			this.lockPosition = lockPosition;
			this.top = top;
		}
		
		public function flip(forward:Boolean = true):Boolean
		{
			if(locked)
				return false;
			if(canFlip())
			{
				if(forward)
					++currentPosition;
				else
					--currentPosition;
				
				timeline.play();
				timeline.reverse = !forward;
				timeline.handleLabel(POSITION+currentPosition,stop)
				return true;
			}
			return false;
		}
		
		private function stop():void
		{
			timeline.gotoAndStop(timeline.currentIndex);
			flipped.dispatch();
			if(currentPosition == lockPosition)
				locked = true;
		}
	}
}