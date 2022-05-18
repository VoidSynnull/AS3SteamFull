package game.components.specialAbility
{
	import ash.core.Entity;
	
	import ash.core.Component;
	
	public class WhoopeeCushionComponent extends Component
	{
		public var isNewSound:Boolean = false;
		public var isTriggered:Boolean = false;
		public var lastSound:int = 0;
		public var timer:Number = 0;
		
		public var emitterEntity:Entity = new Entity;
	}
}