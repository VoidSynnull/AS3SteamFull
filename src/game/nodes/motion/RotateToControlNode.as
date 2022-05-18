package game.nodes.motion
{
	import engine.components.Spatial;
	import game.components.motion.RotateControl;
	import ash.core.Node;
	import game.components.motion.TargetSpatial;

	public class RotateToControlNode extends Node
	{
		public var spatial:Spatial;
		public var target:TargetSpatial;
		public var rotateControl:RotateControl;
	}
}