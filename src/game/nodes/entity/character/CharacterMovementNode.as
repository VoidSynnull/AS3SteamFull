package game.nodes.entity.character
{
	import ash.core.Node;
	
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.animation.FSMControl;
	import game.components.entity.character.CharacterMotionControl;
	import game.components.entity.character.CharacterMovement;
	import game.components.motion.Edge;
	import game.components.motion.MotionControl;
	import game.components.motion.MotionTarget;
	
	public class CharacterMovementNode extends Node
	{
		public var fsmControl:FSMControl;
		public var spatial:Spatial;
		public var motion:Motion;
		public var motionControl:MotionControl;
		public var motionTarget:MotionTarget;
		public var charMotionControl:CharacterMotionControl;
		public var edge:Edge;
		public var charMovement:CharacterMovement;
		
	}
}