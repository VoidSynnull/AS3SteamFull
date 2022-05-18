package game.scenes.ghd.shared.fallingRocks
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;
	
	import game.components.entity.Children;
	
	public class MeteorHitRockNode extends Node
	{
		public var rock:MeteorHitRock;
		public var spatial:Spatial;
		public var display:Display;
		public var id:Id;
		
		// childs should be hit types associated with the rock
		public var child:Children;
		
	}
}