package game.scenes.carrot.smelter.components
{
	import ash.core.Component;
	import engine.components.Motion;
	
	import game.components.hit.Mover;
	
	public class Conveyor extends Component
	{
		public var easing:Number = 15;
		
		public var isMoving:Boolean = true;
		public var gears:Boolean = true;
		
		public var motion:Motion;
		public var mover:Mover;
	}
}