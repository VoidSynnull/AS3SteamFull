package game.nodes.entity.collider
{
	import ash.core.Node;
	
	import engine.components.Motion;
	
	import game.components.motion.Edge;
	import game.components.audio.HitAudio;
	import game.components.entity.collider.BitmapCollider;
	import game.components.hit.CurrentHit;
	import game.components.hit.ValidHit;
	
	public class BitmapCollisionNode extends Node
	{
		public var motion : Motion;
		public var collider : BitmapCollider;
		public var currentHit:CurrentHit;
		public var hitAudio:HitAudio;
		public var edge:Edge;
		public var validHit:ValidHit;
		public var optional:Array = [HitAudio,Edge,ValidHit];
	}
}