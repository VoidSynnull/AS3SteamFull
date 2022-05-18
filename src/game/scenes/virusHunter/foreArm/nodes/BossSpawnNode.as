package game.scenes.virusHunter.foreArm.nodes
{
	import ash.core.Node;
	
	import engine.components.Spatial;
	
	import game.components.entity.Children;
	import game.components.timeline.Timeline;
	import game.scenes.virusHunter.foreArm.components.BossSpawn;
	
	public class BossSpawnNode extends Node
	{
		public var bossSpawn:BossSpawn;
		public var children:Children;
		public var timeline:Timeline;
		public var spatial:Spatial;
	}
}