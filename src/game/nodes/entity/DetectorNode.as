package game.nodes.entity
{
	import ash.core.Node;
	
	import engine.components.Spatial;
	import engine.components.SpatialAddition;
	
	import game.components.entity.Detector;
	
	public class DetectorNode extends Node
	{
		public var detector:Detector;
		public var spatial:Spatial;
		public var spatialAddition:SpatialAddition;
	}
}