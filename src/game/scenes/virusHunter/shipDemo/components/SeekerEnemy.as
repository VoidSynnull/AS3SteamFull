package game.scenes.virusHunter.shipDemo.components
{
	import ash.core.Component;
	
	public class SeekerEnemy extends Component
	{
		public function SeekerEnemy()
		{
			super();
		}
		
		public var state:String;
		public var lifetime:Number;
		public const AQUIRE:String = "aquire";
		public const ATTACK:String = "attack";
		public const SEEK:String = "seek";
		public const DIE:String = "die";
		public const INACTIVE:String = "inactive";
	}
}