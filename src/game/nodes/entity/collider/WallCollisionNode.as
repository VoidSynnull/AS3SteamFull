package game.nodes.entity.collider
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.audio.HitAudio;
	import game.components.entity.collider.BitmapCollider;
	import game.components.entity.collider.WallCollider;
	import game.components.hit.CurrentHit;
	import game.components.hit.ValidHit;
	import game.components.motion.Edge;
	
	public class WallCollisionNode extends Node
	{
		public var spatial:Spatial;
		public var motion:Motion;
		public var collider:WallCollider;
		public var display:Display;
		public var bitmapCollider:BitmapCollider;
		public var currentHit:CurrentHit;
		public var hitAudio:HitAudio;
		public var id:Id;
		public var validHit:ValidHit;
		public var edge:Edge;
		public var optional:Array = [HitAudio,Id,ValidHit,Edge];
	}
}