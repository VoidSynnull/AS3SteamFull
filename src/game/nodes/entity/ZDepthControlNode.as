package game.nodes.entity
{
	import ash.core.Node;
	
	import engine.components.Display;
	
	import game.components.entity.ZDepthControl;
	
	public class ZDepthControlNode extends Node
	{
		public var zDepthControl:ZDepthControl;
		public var display:Display;
	}
}