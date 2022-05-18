package game.nodes.hit
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;
	
	import game.components.hit.Zone;
	
	public class ZoneHitNode extends Node
	{
		public var zone:Zone;
		public var spatial:Spatial;
		public var display:Display;
		public var id:Id;
	}
}