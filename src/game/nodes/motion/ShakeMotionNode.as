package game.nodes.motion
{
	import ash.core.Node;
	import engine.components.Spatial;
	import engine.components.SpatialAddition;
	import game.components.motion.ShakeMotion;

	public class ShakeMotionNode extends Node
	{
		public var shakeMotion : ShakeMotion;
		public var spatial : Spatial;
		public var spatialAddition : SpatialAddition;
	}
}