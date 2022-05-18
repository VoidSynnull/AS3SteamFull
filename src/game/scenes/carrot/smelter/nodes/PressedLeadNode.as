package game.scenes.carrot.smelter.nodes
{
	import ash.core.Node;
	
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.entity.Sleep;
	import game.scenes.carrot.smelter.components.PressedLeadComponent;
	
	public class PressedLeadNode extends Node
	{
		public var sleep:Sleep;
		public var spatial:Spatial;
		public var motion:Motion;
		public var lead:PressedLeadComponent;
	}
}