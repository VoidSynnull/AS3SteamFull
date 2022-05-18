package engine.nodes
{
	import ash.core.Node;
	
	import engine.components.Spatial;
	import engine.components.SpatialOffset;
	import engine.components.SpatialWrap;
	
	public class SpatialWrapNode extends Node
	{
		public var spatialWrap:SpatialWrap;
		public var spatial:Spatial;
		public var spatialOffset:SpatialOffset;
	}
}