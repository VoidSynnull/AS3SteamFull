package game.scenes.testIsland.drewTest.nodes
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.scenes.testIsland.drewTest.components.Wind;
	
	public class WindNode extends Node
	{
		public var wind:Wind;
		public var spatial:Spatial;
		public var display:Display;
	}
}