package game.nodes.entity.character
{
	import ash.core.Node;
	
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.entity.character.CharacterWander;
	
	public class CharacterWanderNode extends Node
	{
		public var characterWander:CharacterWander;
		public var spatial:Spatial;
		public var motion:Motion;
	}
}