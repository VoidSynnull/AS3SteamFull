package game.nodes.entity.collider
{
	import ash.core.Node;
	
	import engine.components.Motion;
	import engine.components.MotionBounds;
	import engine.components.Spatial;
	
	import game.components.audio.HitAudio;
	import game.components.hit.CurrentHit;
	import game.components.entity.collider.PlatformCollider;
	
	public class BoundsCollisionNode extends Node
	{
		//public var spatial:Spatial;
		public var motion:Motion;
		public var collider:PlatformCollider;
		public var bounds:MotionBounds;
		public var currentHit:CurrentHit;
		public var hitAudio:HitAudio;
		public var optional:Array = [HitAudio];
	}
}
