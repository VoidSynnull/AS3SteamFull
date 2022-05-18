package game.nodes.entity
{

	import ash.core.Node;
	
	import engine.components.Display;
	
	import game.components.entity.character.ColorSet;

	public class ColorDisplayNode extends Node
	{
		public var colorSet:ColorSet;
		
		public var display:Display;
		public var optional:Array = [Display];
	}
}
