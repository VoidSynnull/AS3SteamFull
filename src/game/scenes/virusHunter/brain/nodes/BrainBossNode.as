package game.scenes.virusHunter.brain.nodes
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.components.timeline.Timeline;
	import game.scenes.virusHunter.brain.components.BrainBoss;
	import game.scenes.virusHunter.brain.components.HitPoints;
	import game.scenes.virusHunter.shared.components.EnemySpawn;

	public class BrainBossNode extends Node
	{
		public var brainBoss:BrainBoss;
		public var hitPoints:HitPoints;
		public var display:Display;
		public var spatial:Spatial;
		public var enemySpawn:EnemySpawn;
		public var timeline:Timeline;
	}
}