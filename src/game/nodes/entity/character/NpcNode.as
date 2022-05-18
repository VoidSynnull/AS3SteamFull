package game.nodes.entity.character
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.components.entity.character.Npc;
	
	public class NpcNode extends Node
	{
		public var npc:Npc;
		public var spatial:Spatial;
		public var display:Display;
	}
}