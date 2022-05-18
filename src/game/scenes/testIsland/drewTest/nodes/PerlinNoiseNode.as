package game.scenes.testIsland.drewTest.nodes
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.scenes.testIsland.drewTest.components.PerlinNoise;
	
	public class PerlinNoiseNode extends Node
	{
		public var noise:PerlinNoise;
		public var display:Display;
		public var spatial:Spatial;
	}
}