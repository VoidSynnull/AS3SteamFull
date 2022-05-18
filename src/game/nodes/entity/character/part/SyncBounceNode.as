package game.nodes.entity.character.part
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.components.entity.character.part.SyncBounce;

	public class SyncBounceNode extends Node
	{
		public var syncBounce:SyncBounce;
		public var display:Display;
		public var spatial:Spatial;
	}
}