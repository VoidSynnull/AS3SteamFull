package game.comicViewer.nodes
{
	import ash.core.Node;
	
	import engine.components.Spatial;
	
	import game.components.motion.Edge;
	import game.comicViewer.components.StayInBounds;
	
	public class StayInBoundsNode extends Node
	{
		public var spatial:Spatial;
		public var stayInBounds:game.comicViewer.components.StayInBounds;
		public var edge:Edge;
	}
}