package game.scenes.carrot.smelter.nodes 
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.entity.Sleep;
	import game.scenes.carrot.smelter.components.Molten;
	
	public class MoltenNode extends Node
	{
		public var molten:Molten;
		public var spatial:Spatial;
		public var motion:Motion;
		public var display:Display;
		public var sleep:Sleep;
	}
}