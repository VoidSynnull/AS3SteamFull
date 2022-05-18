package game.scenes.backlot.cityDestroy.nodes
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.animation.FSMControl;
	import game.scenes.backlot.cityDestroy.components.Health;
	import game.scenes.backlot.cityDestroy.components.SoldierHit;
	
	public class SoldierHitNode extends Node
	{
		public var hit:SoldierHit;
		public var motion:Motion;
		public var spatial:Spatial;
		public var display:Display;
		public var health:Health;
		public var state:FSMControl;
	}
}