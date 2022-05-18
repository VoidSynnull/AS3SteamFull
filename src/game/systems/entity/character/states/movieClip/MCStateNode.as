package game.systems.entity.character.states.movieClip
{
	import ash.core.Node;
	
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.animation.FSMControl;
	import game.components.entity.character.CharacterMotionControl;
	import game.components.entity.character.CharacterMovement;
	import game.components.entity.collider.ClimbCollider;
	import game.components.entity.collider.HazardCollider;
	import game.components.entity.collider.PlatformCollider;
	import game.components.entity.collider.WallCollider;
	import game.components.entity.collider.WaterCollider;
	import game.components.hit.CurrentHit;
	import game.components.motion.Edge;
	import game.components.motion.MotionControl;
	import game.components.motion.MotionTarget;
	import game.components.timeline.Timeline;
	
	public class MCStateNode extends Node
	{
		public var fsmControl:FSMControl;
		
		public var timeline:Timeline;
		public var spatial:Spatial;
		public var motion:Motion;
		public var edge:Edge;
		
		public var charMotionControl:CharacterMotionControl;
		public var motionControl:MotionControl;
		public var motionTarget:MotionTarget;
		public var charMovement:CharacterMovement;
		
		// colliders
		public var climbCollider:ClimbCollider;
		public var waterCollider:WaterCollider;
		public var platformCollider:PlatformCollider;
		public var hazardCollider:HazardCollider;
		public var wallCollider:WallCollider;
		public var currentHit:CurrentHit;
		public var optional:Array = [ClimbCollider, WaterCollider, PlatformCollider, HazardCollider, CurrentHit, WallCollider];
	}
}