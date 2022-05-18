package game.scenes.virusHunter.shared.nodes
{
	import ash.core.Node;
	
	import engine.components.Spatial;
	
	import game.scenes.virusHunter.shared.components.EnemySpawn;
	
	public class EnemySpawnNode extends Node
	{
		public var spawn:EnemySpawn;
		public var spatial:Spatial;
	}
}