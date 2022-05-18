package game.nodes.entity.character.part
{
	import ash.core.Node;
	
	import engine.components.Display;
	
	import game.components.entity.Parent;
	import game.components.entity.character.part.DripPart;
	
	public class DripPartNode extends Node
	{
		public var display:Display;
		public var dripPart:DripPart;
		public var parent:Parent;
	}
}