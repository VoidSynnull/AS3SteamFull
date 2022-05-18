package game.scenes.myth.mountOlympus3.nodes
{
	import ash.core.Node;
	
	import engine.components.Motion;
	import engine.components.MotionBounds;
	import engine.components.Spatial;
	
	import game.components.animation.FSMControl;
	import game.components.entity.EntityPoolComponent;
	import game.components.entity.character.CharacterMotionControl;
	import game.components.entity.character.Player;
	import game.components.entity.character.animation.AnimationControl;
	import game.components.entity.character.animation.RigAnimation;
	import game.components.entity.collider.HazardCollider;
	import game.components.hit.CurrentHit;
	import game.components.motion.Edge;
	import game.components.motion.MotionControl;
	import game.components.motion.MotionTarget;
	import game.components.timeline.Timeline;
	import game.scenes.myth.mountOlympus3.components.FlightComponent;
	import game.scenes.myth.shared.components.CloudMass;
	
	public class CloudCharacterStateNode extends Node
	{
		public var fsmControl:FSMControl;
		
		public var player:Player;
		public var animControl:AnimationControl;
		public var primary:RigAnimation;
		public var timeline:Timeline;
		public var spatial:Spatial;
		public var motion:Motion;
		public var edge:Edge;
		
		public var charMotionControl:CharacterMotionControl;
		public var motionControl:MotionControl;
		public var motionTarget:MotionTarget;
		public var motionBounds:MotionBounds;
		
		// cloud specifc
		public var clouds:CloudMass;
		public var bolts:EntityPoolComponent;
		public var flight:FlightComponent;
		
		// colliders
		public var hazardCollider:HazardCollider;
		public var currentHit:CurrentHit;
		public var optional:Array = [HazardCollider, CurrentHit];
	}
}