package game.scenes.virusHunter.shipDemo.components
{
	import ash.core.Entity;
	
	import ash.core.Component;
	
	public class SnakeEnemy extends Component
	{
		public function SnakeEnemy()
		{
			super();
		}
		
		public var state:String;
		public var next:Entity;
		public var deathWait:Number = .2;
		public var attackDistance:Number;
		public const WAITING_TO_DIE:String = "waitingToDie";
		public const AQUIRE:String = "aquire";
		public const ATTACK:String = "attack";
		public const SEEK:String = "seek";
		public const DIE:String = "die";
		public const INACTIVE:String = "inactive";
	}
}