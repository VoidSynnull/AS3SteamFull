package game.scenes.virusHunter.shipDemo.nodes
{
	import ash.core.Node;
	
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.entity.Sleep;
	import game.scenes.virusHunter.shared.components.DamageTarget;
	import game.scenes.virusHunter.shipDemo.components.PointValue;
	import game.scenes.virusHunter.shipDemo.components.SeekerEnemy;
	
	public class SeekerEnemyNode extends Node
	{
		public var seeker:SeekerEnemy;
		public var motion:Motion;
		public var spatial:Spatial;
		public var damageTarget:DamageTarget;
		public var pointValue:PointValue;
		public var sleep:Sleep;
	}
}