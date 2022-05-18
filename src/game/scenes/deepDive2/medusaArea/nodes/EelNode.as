package game.scenes.deepDive2.medusaArea.nodes 
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Spatial;
	import engine.components.SpatialOffset;
	
	import game.components.timeline.Timeline;
	import game.scenes.deepDive2.medusaArea.components.Eel;
	
	public class EelNode extends Node
	{
		public var eel:Eel;
		public var display:Display;
		public var spatial:Spatial;
		public var timeline:Timeline;
		public var spatialOffset:SpatialOffset;
	}
}