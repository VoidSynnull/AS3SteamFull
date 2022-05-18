package game.scenes.arab3.atriumGame.searchTimer
{
	import ash.core.Component;
	import ash.core.Entity;
	
	import org.osflash.signals.Signal;
	
	public class SearchTimer extends Component
	{
		internal var _running:Boolean = false;
		internal var _remainingTime:Number = 0;
		
		public var finished:Signal = new Signal(Entity);
		
		public function SearchTimer()
		{
			super();
		}
		
		public function get running():Boolean
		{
			return this._running;
		}
		
		public function set running(running:Boolean):void
		{
			this._running = running;
		}
		
		public function get remainingTime():Number
		{
			return this._remainingTime;
		}
		
		public function set remainingTime(remainingTime:Number):void
		{
			if(isFinite(remainingTime) && remainingTime >= 0)
			{
				this._remainingTime = remainingTime;
			}
		}
	}
}