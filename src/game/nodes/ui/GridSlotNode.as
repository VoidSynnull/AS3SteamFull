package game.nodes.ui
{
	import ash.core.Node;
	
	import engine.components.Spatial;
	
	import game.components.entity.Sleep;
	import game.components.motion.Edge;
	import game.components.ui.GridSlot;
	
	public class GridSlotNode extends Node
	{
		public var gridSlot:GridSlot;
		//public var gridControl:GridControlScrollable;
		public var spatial:Spatial;
		public var sleep:Sleep;
		public var edge:Edge;
	}
}