package game.scenes.virusHunter.heart.nodes {

	import ash.core.Node;
	
	import game.scenes.virusHunter.heart.components.RigidArm;
	import game.scenes.virusHunter.heart.components.RigidArmMode;
	import game.scenes.virusHunter.heart.components.RigidArmTarget;

	public class ArmTargetNode extends Node {

		public var arm:RigidArm;
		public var mode:RigidArmMode;

		public var target:RigidArmTarget;

	} // End RigidArmInfoNode

} // End package