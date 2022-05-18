package game.nodes.entity
{
	import ash.core.Node;
	
	import engine.components.OwningGroup;
	
	import game.components.entity.Dialog;
	
	public class DialogNode extends Node
	{
		public var dialog:Dialog;
		public var owningGroup:OwningGroup;
	}
}