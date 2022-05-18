package game.scenes.map.map.nodes
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.scenes.map.map.components.Bird;
	
	public class BirdNode extends Node
	{
		public var bird:Bird;
		public var spatial:Spatial;
		public var display:Display;
	}
}