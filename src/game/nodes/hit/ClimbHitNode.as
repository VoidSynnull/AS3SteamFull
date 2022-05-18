package game.nodes.hit
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;
	
	import game.components.hit.Climb;
	
	public class ClimbHitNode extends Node
	{
		public var spatial : Spatial;
		public var display : Display;
		public var hit : Climb;
		public var id:Id;
		public var optional:Array = [Id];
	}
}
