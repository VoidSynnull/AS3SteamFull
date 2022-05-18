package game.scenes.virusHunter.shared.nodes
{
	import ash.core.Node;
	
	import engine.components.Display;
	
	import game.scenes.virusHunter.shared.components.DamageTarget;
	import game.scenes.virusHunter.shared.components.EnemyEye;
	
	public class EnemyEyeNode extends Node
	{
		public var enemyEye:EnemyEye;
		public var damageTarget:DamageTarget;
		public var display:Display;
	}
}