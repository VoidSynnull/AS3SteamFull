package game.scenes.viking.fortress.nodes 
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.scenes.viking.fortress.components.FortressTrash;
	
	public class FortressTrashNode extends Node
	{
		public var trash:FortressTrash;
		public var display:Display;
		public var spatial:Spatial;
	}
}