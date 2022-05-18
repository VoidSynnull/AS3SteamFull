package game.nodes.entity.character
{
	import ash.core.Node;
	
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.motion.Edge;
	import game.components.animation.FSMControl;
	import game.components.motion.MotionControl;
	import game.components.motion.MotionTarget;
	import game.components.motion.Navigation;
	import game.components.entity.character.CharacterMotionControl;
	import game.components.entity.character.Player;
	import game.components.entity.collider.PlatformCollider;
	import game.components.motion.TargetEntity;

	public class CharacterJumpAssistNode extends Node
	{
		public var fsmControl : FSMControl;
		public var charMotionControl : CharacterMotionControl;
		public var spatial : Spatial;
		public var motion : Motion;
		public var motionControl : MotionControl;
		public var motionTarget : MotionTarget;
		public var edge:Edge;
		public var player:Player;  // for now, only player can do this.
		
		public var navigation:Navigation;
		public var target:TargetEntity;
		public var platformCollider:PlatformCollider;
		public var optional:Array = [Navigation, TargetEntity, PlatformCollider];
	}
}
