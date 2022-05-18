package game.scenes.virusHunter.shared.nodes
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.components.hit.MovieClipHit;
	import game.scenes.virusHunter.shared.components.Projectile;
	import engine.components.EntityType;
	
	public class ProjectileCollisionNode extends Node
	{
		public var projectile:Projectile;
		public var hit:MovieClipHit;
		public var type:EntityType;
		public var spatial:Spatial;
		public var display:Display;
	}
}