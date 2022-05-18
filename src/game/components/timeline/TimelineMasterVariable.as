package game.components.timeline
{	
	import ash.core.Component;
	
	public class TimelineMasterVariable extends Component
	{
		public function TimelineMasterVariable( frameRate:int = 32 )
		{
			this.frameRate = frameRate;
		}
		
		public var timeAccumulator:Number = 0;
		private var _frameRate:int = 32;				//frames per second
		public var precise:Boolean = false;				// if precise is true timeAccumulator accounts for remainder, otherwise timeAccumulator returns to zero on each frame advance
		public function get frameRate():int { return _frameRate; }
		public function set frameRate( value:int):void
		{ 
			_frameRate =  value;
			_timePerFrame = 1/_frameRate; 	//convert to milliseconds per frame
		}
		private var _timePerFrame:Number = .032;		// milliseconds per frame
		public function get timePerFrame():Number { return _timePerFrame; }	//frames per second
		
		
	}
}
