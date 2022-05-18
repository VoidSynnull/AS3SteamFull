package game.nodes.hit
{
	import ash.core.Node;
	
	import engine.components.Id;
	import engine.components.Motion;
	
	import game.components.hit.Projectile;
	
	public class ProjectileHitNode extends Node
	{
		public var projectile:Projectile;
		public var motion:Motion;
		public var id:Id;
	}
}