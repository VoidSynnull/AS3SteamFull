package game.nodes.entity.character.part
{
	import ash.core.Node;
	
	import engine.components.Display;
	
	import game.components.entity.Parent;
	import game.components.entity.character.part.FlipPart;
	
	public class FlipPartNode extends Node
	{
		public var display:Display;
		public var flipPart:FlipPart;
		public var parent:Parent;
	}
}