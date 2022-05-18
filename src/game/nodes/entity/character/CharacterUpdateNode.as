package game.nodes.entity.character
{
	import ash.core.Node;
	import engine.components.Display;
	import engine.components.OwningGroup;
	import engine.components.Spatial;
	import game.components.entity.character.Character;
	import engine.components.Id;

	public class CharacterUpdateNode extends Node
	{		  
		public var character:Character;
		public var display:Display;
		public var spatial:Spatial;
		public var owningGroup:OwningGroup;
		public var id:Id
	}
}
