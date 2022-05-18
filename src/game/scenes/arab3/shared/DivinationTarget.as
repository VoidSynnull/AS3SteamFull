package game.scenes.arab3.shared
{
	import ash.core.Component;
	
	import org.osflash.signals.Signal;
	
	public class DivinationTarget extends Component
	{
		// divination responder looks for this component to trigger divination effects on it's owner
		public var response:Signal;
		
		public function DivinationTarget()
		{
			response = new Signal();
		}
		
	}
}