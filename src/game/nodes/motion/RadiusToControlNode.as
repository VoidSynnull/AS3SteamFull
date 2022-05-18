package game.nodes.motion
{
	import ash.core.Node;
	import engine.components.Spatial;
	import game.components.motion.RadiusControl;
	import game.components.motion.TargetSpatial;

	public class RadiusToControlNode extends Node
	{
		public var spatial:Spatial;
		public var target:TargetSpatial;
		public var radiusControl:RadiusControl;
	}
}