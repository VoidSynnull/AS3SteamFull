package game.nodes.entity.collider
{
	import ash.core.Node;
	
	import engine.components.Id;
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.audio.HitAudio;
	import game.components.entity.collider.BitmapCollider;
	import game.components.entity.collider.PlatformReboundCollider;
	import game.components.entity.collider.PlatformCollider;
	import game.components.hit.CurrentHit;
	import game.components.hit.ValidHit;
	import game.components.motion.Edge;
	
	public class BitmapPlatformCollisionNode extends Node
	{
		public var spatial:Spatial;
		public var motion:Motion;
		public var platformCollider:PlatformCollider;
		public var bouncePlatformCollider:PlatformReboundCollider;
		public var bitmapCollider:BitmapCollider;
		public var currentHit:CurrentHit;
		public var hitAudio:HitAudio;
		public var id:Id;
		public var edge:Edge;
		public var validHit:ValidHit;
		public var optional:Array = [HitAudio,Id,Edge,ValidHit,PlatformCollider,PlatformReboundCollider];
	}
}