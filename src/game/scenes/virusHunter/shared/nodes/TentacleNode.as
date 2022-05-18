package game.scenes.virusHunter.shared.nodes 
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.components.entity.Sleep;
	import game.scenes.virusHunter.shared.components.Tentacle;

	public class TentacleNode extends Node
	{
		public var tentacle:Tentacle;
		public var spatial:Spatial;
		public var display:Display;
		public var sleep:Sleep;
	}
}