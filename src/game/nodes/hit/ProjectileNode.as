package game.nodes.hit
{
	import ash.core.Node;
	
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.hit.Projectile;
	
	public class ProjectileNode extends Node
	{
		public var projectile:Projectile;
		public var spatial:Spatial;
		public var motion:Motion;
	}
}