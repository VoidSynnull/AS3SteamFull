package game.scenes.virusHunter.shipDemo.components
{
	import ash.core.Component;
	
	public class OverlordEnemy extends Component
	{
		public function OverlordEnemy()
		{
			super();
		}
		
		public var state:String;
		public var attackDistance:Number;
		public const AQUIRE:String = "aquire";
		public const ATTACK:String = "attack";
		public const SEEK:String = "seek";
		public const DIE:String = "die";
		public const INACTIVE:String = "inactive";
	}
}