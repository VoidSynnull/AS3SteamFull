package game.nodes.ui
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Spatial;
	import engine.components.Tween;
	
	import game.components.ui.FloatingToolTip;
	import game.components.ui.ToolTip;
	
	public class ToolTipNode extends Node
	{
		public var toolTip:ToolTip;
		public var spatial:Spatial; 
		public var display:Display;
		public var floatingToolTip:FloatingToolTip;
		public var tween:Tween;
	}
}
