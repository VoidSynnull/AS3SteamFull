package game.scenes.deepDive1.shared.components
{	
	import ash.core.Component;
	
	import game.scenes.deepDive1.shared.data.FishPathData;
	
	import org.osflash.signals.Signal;
	
	public class FishPath extends Component
	{
		public function FishPath(){ 
			data = new Vector.<FishPathData>();
			pathTargetReached = new Signal();
		}
		public var data:Vector.<FishPathData>;
		public var currentIndex:int = 0;
		public var reachedPath:Boolean = true;
		public var idleLabel:String = "idle";
		public var movingLabel:String = "swim";
		
		private var _nextIndex:int = -1;
		public function get nextIndex():int { return _nextIndex; }
		public function set nextIndex(value:int):void 
		{  
			if(value >= 0 && value < data.length){
				_nextIndex = value;
				reachedPath = false;
			}
		}
		
		
		public var pathTargetReached:Signal;
		
		public function getCurrentData():FishPathData{
			if(currentIndex >= data.length){
				currentIndex = data.length-1;
			}
			return data[currentIndex];
		}
	}
}