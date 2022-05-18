package game.scenes.time.mali.components
{
	
	import ash.core.Entity;
	
	import ash.core.Component;
	import engine.components.Spatial;
	
	public class SnakeLunge extends Component
	{
		public var snakeHit:Entity;
		public var strikeSpace:Spatial;
		public var lunging:Boolean = false;
	}
}