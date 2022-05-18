package game.scenes.map.map.nodes
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.scenes.map.map.components.MapCloud;
	
	public class MapCloudNode extends Node
	{
		public var cloud:MapCloud;
		public var spatial:Spatial;
		public var display:Display;
	}
}