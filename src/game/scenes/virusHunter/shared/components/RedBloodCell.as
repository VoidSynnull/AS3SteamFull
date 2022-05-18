package game.scenes.virusHunter.shared.components
{
	import ash.core.Component;
	
	import game.scenes.virusHunter.shared.data.EnemyType;
	
	public class RedBloodCell extends Component
	{
		public function RedBloodCell()
		{
			
		}
		
		public var state:String;
		public var recycleDistance:Number = 600;
		public var seekVelocity:Number = 50;
		public var type:String = EnemyType.RED_BLOOD_CELL;
		
		// animation properties
		public var angle:Number;
		public var turnSpeed:Number;
		public var radius:Number;
		
		public const FLOAT:String = "seek";
		public const DIE:String = "die";
		public const INACTIVE:String = "inactive";
	}
}