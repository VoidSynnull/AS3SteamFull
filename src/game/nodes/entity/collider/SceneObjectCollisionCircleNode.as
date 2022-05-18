package game.nodes.entity.collider
{
	import ash.core.Node;
	
	import engine.components.Id;
	import engine.components.Motion;
	
	import game.components.audio.HitAudio;
	import game.components.entity.collider.CircularCollider;
	import game.components.entity.collider.RadialCollider;
	import game.components.entity.collider.SceneObjectCollider;
	import game.components.entity.collider.WallCollider;
	import game.components.hit.ValidHit;
	import game.components.motion.Edge;
	import game.components.motion.Mass;
	
	public class SceneObjectCollisionCircleNode extends Node
	{
		public var sceneObjectCollider:SceneObjectCollider;
		public var circleCollider:CircularCollider;
		public var motion:Motion;
		
		public var hitAudio:HitAudio;
		public var id:Id;
		public var validHit:ValidHit;
		public var edge:Edge;
		public var radialCollider:RadialCollider;
		public var wallCollider:WallCollider;
		public var mass:Mass;
		public var optional:Array = [HitAudio,Id,ValidHit,Edge,RadialCollider,WallCollider,Mass];
	}
}