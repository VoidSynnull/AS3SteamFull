package game.scenes.deepDive1.shared.nodes
{
	import ash.core.Node;
	
	import engine.components.Motion;
	
	import game.components.entity.Sleep;
	import game.scenes.deepDive1.shared.components.Fish;
	
	public class FishNode extends Node
	{
		public var fish:Fish;
		public var sleep:Sleep;
		public var motion:Motion;
	}
}