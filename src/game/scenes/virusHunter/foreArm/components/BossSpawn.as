package game.scenes.virusHunter.foreArm.components
{
	import ash.core.Component;
	
	
	public class BossSpawn extends Component
	{		
		public var bossState:String = ALIVE;
		public var spawnX:Number;
		public var spawnY:Number;
		public var rotation:Number;
		
		public const ALIVE:String = "alive";
		public const DEAD:String = "dead";
		public const DESTROYED:String = "destroyed";
		public const WOUNDED:String = "wounded";
		
		public const HIT:String = "hit";
		public const SPAWN:String = "spawn";
	}
}