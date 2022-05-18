package game.scenes.virusHunter.day2Heart.nodes 
{
	import ash.core.Node;
	
	import engine.components.Spatial;
	
	import game.components.entity.Sleep;
	import game.scenes.virusHunter.day2Heart.components.WormBoss;

	public class WormBossNode extends Node
	{
		public var boss:WormBoss;
		public var spatial:Spatial;
		public var sleep:Sleep;
	}
}