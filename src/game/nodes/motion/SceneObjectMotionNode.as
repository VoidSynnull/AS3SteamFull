package game.nodes.motion
{
	import ash.core.Node;
	
	import engine.components.Motion;
	import engine.components.MotionBounds;
	import engine.components.Spatial;
	
	import game.components.entity.collider.PlatformCollider;
	import game.components.entity.collider.PlatformReboundCollider;
	import game.components.entity.collider.RadialCollider;
	import game.components.entity.collider.WaterCollider;
	import game.components.hit.EntityIdList;
	import game.components.hit.SceneObjectHit;
	import game.components.motion.SceneObjectMotion;
	
	public class SceneObjectMotionNode extends Node
	{
		public var sceneObjectMotion:SceneObjectMotion;
		public var motion:Motion;
		public var spatial:Spatial;
		
		public var motionBounds:MotionBounds;
		public var bouncePlatformCollider:PlatformReboundCollider;
		public var radialCollider:RadialCollider;
		public var waterCollider:WaterCollider;
		public var sceneObjectHit:SceneObjectHit;
		public var platformCollider:PlatformCollider;
		public var hits:EntityIdList;
		public var optional:Array = [PlatformReboundCollider, RadialCollider, WaterCollider, MotionBounds, SceneObjectHit, EntityIdList, PlatformCollider];
	}
}