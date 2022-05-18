package game.scenes.carnival.shared.ferrisWheel.nodes {

	import ash.core.Node;
	
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.scenes.carnival.shared.ferrisWheel.components.RotationTarget;

	public class RotationTargetNode extends Node {

		public var target:RotationTarget;
		public var motion:Motion;

		public var spatial:Spatial;

	} // End TargetAngularVelocityNode

} // End package