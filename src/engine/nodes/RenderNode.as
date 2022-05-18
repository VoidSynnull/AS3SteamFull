package engine.nodes
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Spatial;
	import engine.components.SpatialAddition;
	import engine.components.SpatialOffset;

	public class RenderNode extends Node
	{
		public var spatial:Spatial;
		public var display:Display;
		public var spatialOffset:SpatialOffset;
		public var spatialAddition:SpatialAddition;
		public var optional:Array = [SpatialOffset,SpatialAddition];
	}
}
