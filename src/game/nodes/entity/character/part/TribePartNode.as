package game.nodes.entity.character.part
{
	import ash.core.Node;
	
	import engine.components.Display;
	
	import game.components.entity.Parent;
	import game.components.entity.character.part.TribePart;

	public class TribePartNode extends Node
	{
		public var display:Display;
		public var tribePart:TribePart;	
		public var parent:Parent;
	}
}
