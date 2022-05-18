package game.scenes.con3.shared
{
	import ash.core.Component;
	
	import org.osflash.signals.Signal;
	
	// data component that holds a signal for later access
	public class WrappedSignal extends Component
	{
		public var signal:Signal;
		
		public function WrappedSignal()
		{
			signal = new Signal();
		}
		
		override public function destroy():void
		{
			if(signal){
				signal.removeAll();
				signal = null;
			}
			super.destroy();
		}
	}
}