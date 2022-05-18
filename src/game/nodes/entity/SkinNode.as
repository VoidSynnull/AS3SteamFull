package game.nodes.entity
{
	
	import ash.core.Node;
	
	import engine.components.Display;
	
	import game.components.entity.character.ColorSet;
	import game.components.entity.Parent;
	import game.components.entity.character.Rig;
	import game.components.entity.character.Skin;
	import game.components.entity.character.part.MetaPart;
	import game.components.entity.character.part.Part;
	import game.components.entity.character.part.SkinPart;
	
	public class SkinNode extends Node
	{
		public var skin:Skin
		public var metaPart:MetaPart;
		public var skinPart:SkinPart;
		public var parent:Parent;
		
		// optionals
		public var display:Display;
		public var rig:Rig;
		public var part:Part;
		public var colorSet:ColorSet;
		public var optional:Array = [ Display, Rig, Part, ColorSet ];
		
	}
}
