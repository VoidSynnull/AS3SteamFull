package game.nodes.entity.collider
{
	import ash.core.Node;
	
	import engine.components.Motion;
	
	import game.components.entity.collider.BitmapCollider;
	import game.components.entity.collider.ClimbCollider;
	import game.components.hit.CurrentHit;
	import game.components.hit.ValidHit;
	import game.components.motion.Edge;

	public class ClimbCollisionNode extends Node
	{
		//public var spatial : Spatial;
		public var motion : Motion;
		public var collider : ClimbCollider;
		public var currentHit : CurrentHit;
		public var bitmapCollider : BitmapCollider;
		public var edge : Edge;
		public var validHit:ValidHit;
		public var optional:Array = [ValidHit,BitmapCollider,Edge];
	}
}
