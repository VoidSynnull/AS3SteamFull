package game.nodes.ui
{
	import ash.core.Node;
	
	import engine.components.Display;
	
	import game.components.entity.Parent;
	import game.components.ui.ToolTip;
	import game.components.ui.ToolTipActive;
	
	public class CursorToolTipNode extends Node
	{
		public var toolTip:ToolTip;
		public var toolTipActive:ToolTipActive;
		public var display:Display;
		public var parent:Parent;
		public var optional:Array = [Display, Parent];
	}
}