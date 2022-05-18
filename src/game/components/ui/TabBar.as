package game.components.ui 
{
	import ash.core.Component;
	
	import org.osflash.signals.Signal;

	/**
	 * TabBar manages tab transition, picked up by TabSystem
	 * 
	 * @author Bard McKinley
	 */
	public class TabBar extends Component 
	{
		public var transitionComplete:Signal;
		public var inTransition:Boolean = false;
		
		public function TabBar()
		{
			transitionComplete = new Signal();
		}
	}

}