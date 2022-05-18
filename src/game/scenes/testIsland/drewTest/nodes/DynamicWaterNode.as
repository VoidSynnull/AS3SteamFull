package game.scenes.testIsland.drewTest.nodes
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.scenes.testIsland.drewTest.components.DynamicWater;
	
	public class DynamicWaterNode extends Node
	{
		public var water:DynamicWater;
		public var display:Display;
		public var spatial:Spatial;
	}
}