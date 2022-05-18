package game.nodes.specialAbility
{
	import ash.core.Node;
	
	import game.components.motion.Edge;
	import game.components.motion.MotionControl;
	import game.components.motion.MotionTarget;
	import game.components.entity.character.Player;
	import game.components.specialAbility.SpecialAbilityControl;
	
	public class PlayerSpecialAbilityNode extends Node
	{
		public var player:Player;
		public var specialAbilityControl:SpecialAbilityControl;
		public var motionControl:MotionControl;
		public var motionTarget:MotionTarget;
		public var edge:Edge;
	}
}