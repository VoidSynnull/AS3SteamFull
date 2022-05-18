package game.scenes.virusHunter.shared.components
{
	import ash.core.Component;
	
	public class EnemyGroup extends Component
	{
		public function EnemyGroup(total:uint = 0, spawnPickup:String = null)
		{
			this.remaining = total;
			this.spawnPickup = spawnPickup;
		}
		
		public var remaining:uint;
		public var spawnPickup:String;
	}
}