package game.scenes.testIsland.drewTest.nodes
{
	import ash.core.Node;
	
	import engine.components.Audio;
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.scenes.testIsland.drewTest.components.Lightning;
	
	public class LightningNode extends Node
	{
		public var lightning:Lightning;
		public var display:Display;
		public var spatial:Spatial;
		public var audio:Audio;
	}
}