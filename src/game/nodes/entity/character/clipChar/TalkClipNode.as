package game.nodes.entity.character.clipChar
{
	import ash.core.Node;
	
	import game.components.entity.character.BitmapCharacter;
	import game.components.entity.character.Talk;

	public class TalkClipNode extends Node
	{
		public var talk:Talk;
		public var bitmapChar:BitmapCharacter;
	}
}