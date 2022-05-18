package game.scenes.survival3.shared.components
{
	import ash.core.Component;
	
	public class SignalGui extends Component
	{
		public var bars:int;
		public var signal:RadioSignal;
		public var varyRange:Number;
		public function SignalGui(signal:RadioSignal, bars:int = 5, varyRange:Number = 1)
		{
			this.signal = signal;
			this.bars = bars;
			this.varyRange = varyRange;
		}
	}
}