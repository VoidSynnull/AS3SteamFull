package game.systems.dragAndDrop
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.components.entity.Children;
	import game.components.motion.Edge;

	public class DropNode extends Node
	{
		public var drop:Drop;
		public var capacity:Capacity;
		public var spatial:Spatial;
		public var display:Display;
		public var children:Children;
		
		public var edge:Edge;
		public var validIds:ValidIds;
		
		public var optional:Array = [Edge, ValidIds];
	}
}