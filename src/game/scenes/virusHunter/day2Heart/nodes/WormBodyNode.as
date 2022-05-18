package game.scenes.virusHunter.day2Heart.nodes 
{
	import ash.core.Node;
	
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.entity.Sleep;
	import game.scenes.virusHunter.day2Heart.components.WormBody;

	public class WormBodyNode extends Node
	{
		public var body:WormBody;
		public var spatial:Spatial;
		public var motion:Motion;
		public var sleep:Sleep;
	}
}