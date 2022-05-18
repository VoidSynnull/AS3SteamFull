package engine.command
{
	import org.osflash.signals.Signal;

	public class CommandStep
	{
		public function CommandStep()
		{
			this.completed = new Signal();
			this.completedAll = new Signal();
		}
		
		public function execute():void
		{
			
		}
		
		/**
		 * Call when CommandStep is complete.
		 * @param increment - optional parameter to allow for skipping of subsequent steps // TODO :: Not wild about this implementation though. - bard
		 */
		public function complete( increment:int = 1 ):void
		{
			this.completed.dispatch(increment);
		}
		
		public function completeAll():void
		{
			this.completedAll.dispatch();
		}
		
		public var completed:Signal;
		public var completedAll:Signal;
	}
}