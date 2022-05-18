package game.scenes.virusHunter.shared.nodes
{
	import ash.core.Node;
	
	import game.scenes.virusHunter.shared.components.EnemySpawn;
	import game.scenes.virusHunter.shared.components.EnemyWaves;
	
	public class EnemyWaveNode extends Node
	{
		public var enemyWaves:EnemyWaves;
		public var spawn:EnemySpawn;
	}
}