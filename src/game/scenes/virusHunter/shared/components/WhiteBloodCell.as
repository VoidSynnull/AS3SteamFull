package game.scenes.virusHunter.shared.components
{
	import ash.core.Component;
	
	import game.scenes.virusHunter.shared.data.EnemyType;

	public class WhiteBloodCell extends Component
	{
		public function WhiteBloodCell()
		{
			
		}
		
		public var init:Boolean = false;
		public var state:String;
		public var alwaysAquire:Boolean = false;
		public var stealingWeapon:Boolean = false;
		public var aquireDistance:Number = 1500;
		public var attackDistance:Number = 50;
		public var recycleDistance:Number = 1600;
		public var seekVelocity:Number = 100;
		public var aquireVelocity:Number = 100;
		public var attackVelocity:Number = 10;
		public var type:String = EnemyType.WHITE_BLOOD_CELL;
		public const AQUIRE:String = "aquire";
		public const ATTACK:String = "attack";
		public const IDLE:String = "idle";
		public const SEEK:String = "seek";
		public const EXPLODE:String = "explode";
		public const DIE:String = "die";
		public const INACTIVE:String = "inactive";
		public const EXIT:String = "exit";
	}
}
