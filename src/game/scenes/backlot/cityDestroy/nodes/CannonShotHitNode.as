package game.scenes.backlot.cityDestroy.nodes
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.scenes.backlot.cityDestroy.components.CannonShotHit;
	import game.scenes.backlot.cityDestroy.components.Health;
	
	public class CannonShotHitNode extends Node
	{
		public var hit:CannonShotHit;
		public var spatial:Spatial;
		public var display:Display;
		public var health:Health;
	}
}