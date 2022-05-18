package game.scenes.survival1.shared.components
{
	import ash.core.Entity;
	
	import ash.core.Component;
	import engine.components.Display;
	
	public class PageComponent extends Component
	{
		public var isLeft:Boolean = false;
		
		// for coverpages only
		public var backEntity:Entity;
		public var backDisplay:Display;
		public var frontDisplay:Display;
		public var frontFacing:Boolean = true;
	}
}