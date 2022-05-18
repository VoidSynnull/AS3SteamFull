package game.nodes.motion
{
	import ash.core.Node;
	import engine.components.Spatial;
	import engine.components.SpatialOffset;
	import engine.components.Tween;
	import game.components.motion.Edge;
	import game.components.motion.StretchSquash;

	public class StretchSquashNode extends Node
	{
		public var stretchSquash : StretchSquash;
		public var spatial : Spatial;
		public var spatialOffset : SpatialOffset;
		public var edge : Edge;
		public var tween : Tween;
	}
}