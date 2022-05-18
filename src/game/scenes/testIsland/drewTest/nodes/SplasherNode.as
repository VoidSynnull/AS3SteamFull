package game.scenes.testIsland.drewTest.nodes
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.scenes.testIsland.drewTest.components.Splasher;
	
	public class SplasherNode extends Node
	{
		public var splash:Splasher;
		public var display:Display;
		public var spatial:Spatial;
		public var motion:Motion;
	}
}