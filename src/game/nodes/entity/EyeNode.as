package game.nodes.entity
{
	import ash.core.Node;
	
	import engine.components.Display;
	
	import game.components.entity.Parent;
	import game.components.entity.State;
	import game.components.entity.character.ColorSet;
	import game.components.entity.character.part.Part;
	import game.components.entity.character.part.SkinPart;
	import game.components.entity.character.part.eye.Eyes;

	public class EyeNode extends Node
	{
		public var display:Display;
		public var part:Part;
		public var skinPart:SkinPart;
		public var colorSet:ColorSet;
		public var eyes:Eyes;
		public var state:State;
		public var parent:Parent;
	}
}
