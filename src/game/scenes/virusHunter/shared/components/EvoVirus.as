package game.scenes.virusHunter.shared.components
{
	import ash.core.Component;
	
	import game.scenes.virusHunter.shared.data.EnemyType;
	
	public class EvoVirus extends Component
	{
		public function EvoVirus()
		{
			
		}
		
		public var init:Boolean = false;
		public var state:String;
		public var alwaysAquire:Boolean = false;
		public var aquireDistance:Number = 5000;
		public var attackDistance:Number = 100;
		public var recycleDistance:Number = 5600;
		public var seekVelocity:Number = 150;
		public var aquireVelocity:Number = 150;
		public var type:String = EnemyType.EVO_VIRUS;
		public const AQUIRE:String = "aquire";
		public const ATTACK:String = "attack";
		public const LOCKED_ON:String = "locked_on";
		public const SEEK:String = "seek";
		public const HIT:String = "hit";
		public const EXPLODE:String = "explode";
		public const DIE:String = "die";
		public const INACTIVE:String = "inactive";
	}
}

