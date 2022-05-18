package game.scenes.map.map.nodes
{
	import ash.core.Node;
	
	import engine.components.SpatialAddition;
	
	import game.components.ui.Book;
	import game.scenes.map.map.components.MapControl;
	
	public class MapControlNode extends Node
	{
		public var control:MapControl;
		public var book:Book;
		public var addition:SpatialAddition;
	}
}