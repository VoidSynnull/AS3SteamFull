package
{
	import engine.ShellApi;
	
	import org.osflash.signals.Signal;

	public class ShellStep
	{
		public var stepDescription:String = '';

		internal var _shell:Shell;
		
		private var _complete:Signal = new Signal(ShellStep);
		
		public function ShellStep()
		{
		}
		
		public function get shell():Shell { return this._shell; }
		public function get shellApi():ShellApi { return this._shell._api; }
		public function get complete():Signal { return this._complete; }
		
		public function get index():int
		{
			if(this._shell)
			{
				return this._shell.getStepIndex(this);
			}
			return -1;
		}
		
		internal function buildStep():void
		{
			this.build();
		}
		
		protected function build():void
		{
			//All ShellSteps should call built() when done.
			this.built();
		}
		
		protected final function built(...args):void
		{
			trace(stepDescription + " complete");
			this._complete.dispatch(this);
			this._shell.buildNextStep();
		}
	}
}