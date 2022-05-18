package game.nodes.render
{
	import ash.core.Node;
	
	import engine.components.Display;
	
	import game.components.render.FollowDisplayIndex;
	
	public class FollowDisplayIndexNode extends Node
	{
		public var display:Display;
		public var follow:FollowDisplayIndex;
	}
}