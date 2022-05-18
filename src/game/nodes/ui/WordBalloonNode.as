package game.nodes.ui
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Spatial;
	import engine.components.SpatialOffset;
	
	import game.components.motion.GroupSpatialOffset;
	import game.components.entity.Parent;
	import game.components.ui.WordBalloon;

	public class WordBalloonNode extends Node
	{
		public var wordBalloon:WordBalloon;
		public var spatial:Spatial;
		public var display:Display;
		public var parent:Parent;
		public var offset:SpatialOffset;
		public var groupSpatialOffset:GroupSpatialOffset;
		public var optional:Array = [GroupSpatialOffset];
	}
}
