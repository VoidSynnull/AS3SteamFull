package game.components.entity
{
	import ash.core.Component;
	
	public class AlertSound extends Component
	{
		public function AlertSound( checkReset:Boolean = false )
		{
			this.checkReset = checkReset;
		}
		
		public var active:Boolean = true;
		public var checkReset:Boolean = false;
	}
}