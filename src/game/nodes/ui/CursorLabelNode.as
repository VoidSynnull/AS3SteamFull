package game.nodes.ui
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.components.ui.CursorLabel;
	
	public class CursorLabelNode extends Node
	{
		public var cursorLabel:CursorLabel;
		public var spatial:Spatial;
		public var display:Display;
	}
}