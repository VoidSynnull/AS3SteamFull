package game.nodes.hit
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.motion.Edge;
	import game.components.hit.EntityIdList;
	import game.components.hit.Platform;
	import game.components.hit.SeeSaw;
	
	public class SeeSawNode extends Node
	{
		public var display:Display;
		public var spatial:Spatial;
		public var seeSaw:SeeSaw;
		public var platform:Platform;
		public var entityIdList:EntityIdList;
		public var motion:Motion;
		public var edge:Edge;
		
		public var optional:Array = [EntityIdList];
	}
}