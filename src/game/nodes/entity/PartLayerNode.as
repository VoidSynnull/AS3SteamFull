package game.nodes.entity
{
	import engine.components.Display;
	import game.components.entity.character.part.PartLayer;
	import game.components.entity.character.Rig;
	import game.components.entity.Parent;
	import ash.core.Node;

	public class PartLayerNode extends Node
	{
		public var partLayer:PartLayer;
		public var rig:Rig;
		public var display:Display;
		public var parent:Parent;
	}
}
