package game.scenes.virusHunter.shared.components
{
	import ash.core.Component;
	
	public class Projectile extends Component
	{
		public function Projectile(lifespan:Number = 1, damage:Number = .5)
		{
			this.lifespan = lifespan;
			this.damage = damage;
		}
		
		public var lifespan:Number;    // duration of existance in seconds.
		public var damage:Number;      // damage this will deliver to a vulnerable target (this is multiplied by the weaponTarget damage factor).
		public var type:String;        // weapon type fired from.
		public var level:uint = 0;
		public var color:uint;
		public var size:uint;
		public var spin:Number = 0;
	}
}