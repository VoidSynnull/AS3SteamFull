package game.nodes.entity.collider
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Motion;
	
	import game.components.audio.HitAudio;
	import game.components.entity.collider.BitmapCollider;
	import game.components.entity.collider.PlatformCollider;
	import game.components.entity.collider.WaterCollider;
	import game.components.hit.CurrentHit;
	import game.components.hit.EntityIdList;
	import game.components.hit.Mover;
	import game.components.hit.Platform;
	import game.components.motion.Edge;

	public class WaterCollisionNode extends Node
	{
		public var edge:Edge;
		public var motion:Motion;
		public var collider:WaterCollider;
		public var display:Display;
		
		public var currentHit:CurrentHit;
		public var bitmapCollider:BitmapCollider;
		public var platformCollider:PlatformCollider;
		public var hitAudio:HitAudio;
		public var platformHit:Platform;
		public var moverHit:Mover;
		public var entityIdList:EntityIdList;
		public var optional:Array = [CurrentHit,BitmapCollider,HitAudio,Platform,PlatformCollider,Mover,EntityIdList];
	}
}
