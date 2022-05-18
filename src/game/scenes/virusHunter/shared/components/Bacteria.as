package game.scenes.virusHunter.shared.components
{
	import ash.core.Component;
	
	import game.scenes.virusHunter.shared.data.EnemyType;
	
	public class Bacteria extends Component
	{
		public function Bacteria()
		{
		
		}
		
		public var init:Boolean = false;
		public var asset:String = "scenes/virusHunter/shared/bacteria.swf";
		public var state:String;
		public var recycleDistance:Number = 600;
		public var seekVelocity:Number = 50;
		public var type:String = EnemyType.BACTERIA;
		
		// animation properties
		public var angle:Number;
		public var turnSpeed:Number;
		public var radius:Number;
		
		public const FLOAT:String = "seek";
		public const EXPLODE:String = "explode";
		public const DIE:String = "die";
		public const INACTIVE:String = "inactive";
	}
}