package game.scenes.virusHunter.shipDemo.nodes
{
	import ash.core.Node;
	
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.scenes.virusHunter.shared.components.DamageTarget;
	import game.scenes.virusHunter.shared.components.EnemyGroup;
	import game.scenes.virusHunter.shipDemo.components.PointValue;
	import game.scenes.virusHunter.shipDemo.components.SnakeEnemy;
	
	public class SnakeEnemyNode extends Node
	{
		public var snake:SnakeEnemy;
		public var motion:Motion;
		public var spatial:Spatial;
		public var damageTarget:DamageTarget;
		public var pointValue:PointValue;
		public var enemyGroup:EnemyGroup;
	}
}