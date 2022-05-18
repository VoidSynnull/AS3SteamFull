package game.nodes.entity.collider
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Motion;
	
	import game.components.audio.HitAudio;
	import game.components.entity.collider.BitmapCollider;
	import game.components.entity.collider.HazardCollider;
	import game.components.hit.CurrentHit;
	import game.components.motion.Edge;

	public class HazardCollisionNode extends Node
	{
		public var motion : Motion;
		public var collider : HazardCollider;
		public var display : Display;
		public var currentHit : CurrentHit;
		public var hitAudio:HitAudio;
		public var bitmapCollider:BitmapCollider;
		public var edge:Edge;
		public var optional:Array = [HitAudio, BitmapCollider, Edge];
	}
}
