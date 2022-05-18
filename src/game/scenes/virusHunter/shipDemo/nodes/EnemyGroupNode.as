package game.scenes.virusHunter.shipDemo.nodes
{
	import ash.core.Node;
	
	import engine.components.Spatial;
	
	import game.components.entity.Sleep;
	import game.scenes.virusHunter.shared.components.EnemyGroup;
	
	public class EnemyGroupNode extends Node
	{
		public var enemyGroup:EnemyGroup;
		public var spatial:Spatial;
		public var sleep:Sleep;
	}
}