package game.nodes.hit
{
	import ash.core.Node;
	
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.motion.Edge;
	import game.components.hit.ProjectileCollider;
	
	public class ProjectileCollisionNode extends Node
	{
		public var motion:Motion;
		public var spatial:Spatial;
		public var collider:ProjectileCollider;
		public var edge:Edge;
		public var optional:Array = [Motion, Edge];
	}
}