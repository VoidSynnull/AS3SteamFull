package game.nodes.smartFox
{
	import ash.core.Node;
	
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.entity.character.CharacterMotionControl;
	import game.components.entity.character.CharacterMovement;
	import game.components.motion.MotionControl;
	import game.components.motion.MotionTarget;
	import game.components.smartFox.SFAnt;
	
	public class SFAntNode extends Node
	{
		public var ant:SFAnt;
		public var spatial:Spatial;
		public var charMovement:CharacterMovement;
		public var charMotionControl:CharacterMotionControl;
		public var motion:Motion;
		public var motionTarget:MotionTarget;
		public var motionControl:MotionControl;
	}
}