package game.scenes.poptropolis.archery.nodes 
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.scenes.poptropolis.archery.components.Tree;
	
	public class TreeNode extends Node
	{
		public var tree:Tree;
		public var display:Display;
		public var spatial:Spatial;
	}
}