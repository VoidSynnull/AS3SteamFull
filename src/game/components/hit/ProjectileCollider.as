package game.components.hit
{
	import ash.core.Component;
	
	public class ProjectileCollider extends Component
	{
		public function ProjectileCollider()
		{
			
		}
		
		public var isHit:Boolean = false;
		public var hits:Vector.<String> = new Vector.<String>();  // a list of all projectile id's hitting this collider.
	}
}