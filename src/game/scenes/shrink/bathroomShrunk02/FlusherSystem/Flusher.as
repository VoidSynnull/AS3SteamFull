package game.scenes.shrink.bathroomShrunk02.FlusherSystem
{
	import ash.core.Component;
	
	import game.components.hit.EntityIdList;
	
	import game.components.hit.Platform;
	
	import org.osflash.signals.Signal;
	
	public class Flusher extends Component
	{
		public var flush:Signal;
		public var up:Number;
		public var down:Number;
		public var handle:Platform;
		public var entityIdList:EntityIdList;
		public var flushing:Boolean;
		public var pressTime:Number;
		public function Flusher(handle:Platform, up:Number = 10, down:Number = -25, pressTime:Number = .5)
		{
			flush = new Signal();
			this.up = up;
			this.down = down;
			this.handle = handle;
			this.pressTime = pressTime;
			flushing = false;
		}
	}
}