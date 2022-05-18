package game.nodes.render
{
	import ash.core.Node;
	
	import engine.components.Display;
	
	import game.components.render.DisplayFilter;
	
	public class DisplayFilterNode extends Node
	{
		public var display:Display;
		public var filter:DisplayFilter;
	}
}