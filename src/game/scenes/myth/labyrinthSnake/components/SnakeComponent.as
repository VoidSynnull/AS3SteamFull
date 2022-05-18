package game.scenes.myth.labyrinthSnake.components
{	
	import ash.core.Component;
	
	public class SnakeComponent extends Component
	{
		public function SnakeComponent()
		{
			for( var number:int = 0; number < 13; number ++ )
			{
				activeHoles.push( false );
			}
		}
		
		public var state:String = SPAWN;
		
		public var SPAWN:String = "spawn";
		public var VICTORY:String = "victory";
		
		public var snakesCaught:int = 0;
		public var activeSnakes:int = 0;
		public var activeNormal:int = 0;
		public var activeTarget:int = 0;
		
		public var maxSnakes:int = 3;
		
		public var activeHoles:Vector.<Boolean> = new Vector.<Boolean>;
	}
}