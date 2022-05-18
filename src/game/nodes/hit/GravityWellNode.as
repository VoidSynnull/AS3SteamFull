package game.nodes.hit
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.components.hit.GravityWell;
	
	public class GravityWellNode extends Node
	{
		public var spatial:Spatial;
		public var display:Display;
		public var gravityWellHit:GravityWell;
	}
}