package game.nodes.ui
{
	import ash.core.Node;
	
	import game.components.entity.EntityPoolComponent;
	import game.components.ui.GridControlScrollable;
	import game.components.ui.Ratio;
	import game.components.ui.ScrollBox;
	
	public class GridControlScrollNode extends Node
	{
		public var grid:GridControlScrollable;
		public var ratio:Ratio;
		public var entityPool:EntityPoolComponent;

		public var scrollBox:ScrollBox;
		public var optional:Array = [ScrollBox];
	}
}