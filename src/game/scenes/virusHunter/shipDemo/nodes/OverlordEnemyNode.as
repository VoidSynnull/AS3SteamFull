package game.scenes.virusHunter.shipDemo.nodes
{
	import ash.core.Node;
	
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.scenes.virusHunter.shared.components.DamageTarget;
	import game.scenes.virusHunter.shipDemo.components.OverlordEnemy;
	import game.scenes.virusHunter.shipDemo.components.PointValue;
	
	public class OverlordEnemyNode extends Node
	{
		public var overlord:OverlordEnemy;
		public var motion:Motion;
		public var spatial:Spatial;
		public var damageTarget:DamageTarget;
		public var pointValue:PointValue;
	}
}