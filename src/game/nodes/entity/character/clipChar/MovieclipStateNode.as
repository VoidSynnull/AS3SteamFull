package game.nodes.entity.character.clipChar
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.OwningGroup;
	import engine.components.Spatial;
	
	import game.components.motion.Edge;
	import game.components.animation.FSMControl;
	import game.components.motion.MotionControl;
	import game.components.motion.MotionTarget;
	import game.components.timeline.Timeline;
	import game.components.entity.collider.ClimbCollider;
	import game.components.hit.CurrentHit;
	import game.components.entity.collider.HazardCollider;
	import game.components.entity.collider.PlatformCollider;
	import game.components.entity.collider.WaterCollider;
	
	public class MovieclipStateNode extends Node
	{
		public var display:Display;
		public var fsmControl:FSMControl;
		public var timeline:Timeline;
		public var spatial:Spatial;
		public var motion:Motion;
		
		public var edge:Edge;		
		public var motionControl:MotionControl;
		public var motionTarget:MotionTarget;
		public var owningGroup:OwningGroup;
		
		// colliders
		public var climbCollider:ClimbCollider;
		public var waterCollider:WaterCollider;
		public var platformCollider:PlatformCollider;
		public var hazardCollider:HazardCollider;
		public var currentHit:CurrentHit;
		
		public var optional:Array = [Timeline, ClimbCollider, WaterCollider, PlatformCollider, HazardCollider, CurrentHit, Edge, MotionControl, MotionTarget];
	}
}