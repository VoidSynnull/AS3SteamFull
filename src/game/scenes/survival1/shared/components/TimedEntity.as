package game.scenes.survival1.shared.components
{
	import ash.core.Entity;
	
	import ash.core.Component;
	
	import org.osflash.signals.Signal;
	
	public class TimedEntity extends Component
	{
		public var baseTime:Number;
		public var variation:Number;
		public var eventTime:Number;
		public var cycles:int;
		public var time:Number = 0;
		public var cycle:int = 0;
		public var timesUp:Signal;
		public var paused:Boolean;
		public function TimedEntity(baseTime:Number, variation:Number = 0, cycles:int = 0, startPaused:Boolean = false)
		{
			this.baseTime = baseTime;
			this.variation = variation;
			this.cycles = cycles;
			paused = startPaused;
			timesUp = new Signal(Entity);
			eventTime = baseTime + Math.random() * variation;
		}
	}
}