package game.nodes.ui
{
	import ash.core.Node;
	
	import game.components.timeline.Timeline;
	import game.components.ui.Button;
	import game.components.ui.ToolTip;
	
	public class ButtonNode extends Node
	{
		public var button:Button;
		public var timeline:Timeline;
		
		public var toolTip:ToolTip;
		public var optional:Array = [ToolTip]
	}
}