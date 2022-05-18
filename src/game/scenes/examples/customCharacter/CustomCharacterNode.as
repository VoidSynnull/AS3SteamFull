package game.scenes.examples.customCharacter
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
	import game.components.motion.MotionControl;
	import game.components.motion.MotionTarget;
	import game.components.motion.SceneObjectMotion;
	import game.components.timeline.Timeline;
	
	public class CustomCharacterNode extends Node
	{
		public var customCharacter:CustomCharacterComponent;
		public var motion:Motion;
		public var sceneObjectMotion:SceneObjectMotion;
		public var characterMotionControl:CharacterMotionControl;
		public var motionControl:MotionControl;
		public var spatial:Spatial;
		public var timeline:Timeline;
		//public var motionControlBase:MotionControlBase;
		public var platformCollider:PlatformCollider;
		public var waterCollider:WaterCollider;
		public var climbCollider:ClimbCollider;
		public var characterMovement:CharacterMovement;
		public var motionTarget:MotionTarget;
		public var fsmControl:FSMControl;
		public var hazardCollider:HazardCollider;
		public var wallCollider:WallCollider;
		public var optional:Array = [PlatformCollider, WaterCollider, ClimbCollider, HazardCollider, Timeline];
	}
}