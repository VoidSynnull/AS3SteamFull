package game.nodes.entity.character.part
{
	import ash.core.Node;
	
	import engine.components.Spatial;
	import game.components.entity.character.Rig;
	import game.components.entity.character.part.item.ItemMotion;

	public class ItemMotionNode extends Node
	{
		public var spatial:Spatial;
		public var itemMotion:ItemMotion;	
		public var rig:Rig;
	}
}
