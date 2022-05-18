package game.scenes.myth.cerberus.components
{
	import ash.core.Component;
	
	import engine.components.Display;
	
	public class CerberusControlComponent extends Component
	{
		public var isSoothed:Boolean = false;
		public var teleporting:Boolean = false;
		public var isAttacking:Boolean = false;
		public var isSnoring:Boolean = false;
		
		public var playerDisplay:Display;
	}
}