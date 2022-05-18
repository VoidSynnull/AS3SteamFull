package game.scenes.virusHunter.shared.components
{
	import ash.core.Component;
	
	import game.scenes.virusHunter.shared.data.EnemyType;
	
	public class Virus extends Component
	{
		public function Virus()
		{
		
		}
		
		public var init:Boolean = false;
		public var state:String;
		public var alwaysAquire:Boolean = false;
		public var aquireDistance:Number = 300;
		public var attackDistance:Number = 120;
		public var recycleDistance:Number = 600;
		public var seekVelocity:Number = 50;
		public var aquireVelocity:Number = 100;
		public var type:String = EnemyType.VIRUS;
		public const AQUIRE:String = "aquire";
		public const ATTACK:String = "attack";
		public const SEEK:String = "seek";
		public const EXPLODE:String = "explode";
		public const DIE:String = "die";
		public const INACTIVE:String = "inactive";
		
	}
}