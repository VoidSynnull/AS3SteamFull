package game.nodes.hit
{
	import ash.core.Node;
	
	import engine.components.Id;
	import engine.components.Spatial;
	
	import game.components.hit.ProximityHit;
	
	public class ProximityHitNode extends Node
	{
		public var hit:ProximityHit;
		public var spatial:Spatial;
		public var id:Id;
	}
}