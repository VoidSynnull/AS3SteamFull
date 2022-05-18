package game.nodes.hit
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.entity.collider.RadialCollider;
	import game.components.entity.collider.SceneObjectCollider;
	import game.components.hit.EntityIdList;
	import game.components.hit.SceneObjectHit;
	import game.components.motion.Edge;
	import game.components.motion.Mass;
	import game.data.scene.hit.HitAudioData;
	import game.components.audio.HitAudio;
	
	public class SceneObjectHitNode extends Node
	{
		public var hit:SceneObjectHit;
		public var display:Display;
		public var spatial:Spatial;
		
		public var id:Id;
		public var hits:EntityIdList;
		public var edge:Edge;
		public var motion:Motion;
		public var radialCollider:RadialCollider;
		public var sceneObjectCollider:SceneObjectCollider;
		public var mass:Mass;
		public var hitAudio:HitAudio;
		public var hitAudioData:HitAudioData;
		public var optional:Array = [Id,EntityIdList,Edge,Motion,RadialCollider,SceneObjectCollider,Mass,HitAudio,HitAudioData];
		
	}
}